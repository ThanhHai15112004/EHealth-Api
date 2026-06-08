import { randomUUID } from 'crypto';
import { BillingInvoiceRepository } from '../../repository/Billing/billing-invoices.repository';
import {
    Invoice,
    InvoiceDetail,
    PaymentTransaction,
    CashierShift,
    InvoiceInsuranceClaim,
    CreateInvoiceInput,
    UpdateInvoiceInput,
    AddInvoiceItemInput,
    UpdateInvoiceItemInput,
    CreatePaymentInput,
    RefundInput,
    OpenShiftInput,
    CloseShiftInput,
    RevenueSummary,
    PaginatedResult,
} from '../../models/Billing/billing-invoices.model';
import {
    BILLING_INVOICE_ERRORS,
    BILLING_INVOICE_CONFIG,
    INVOICE_STATUS,
    INVOICE_ITEM_TYPE,
    VALID_PAYMENT_METHODS,
    PAYMENT_STATUS,
} from '../../constants/billing-invoices.constant';

export class BillingInvoiceService {

    private static generateId(prefix: string): string {
        return `${prefix}_${randomUUID().substring(0, 16).replace(/-/g, '')}`;
    }

    /** Tạo mã hóa đơn duy nhất: INV-20260318-XXXX */
    private static generateInvoiceCode(): string {
        const now = new Date();
        const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
        const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
        return `${BILLING_INVOICE_CONFIG.INVOICE_CODE_PREFIX}-${dateStr}-${rand}`;
    }

    /** Tạo mã giao dịch duy nhất: TXN-20260318-XXXX */
    private static generateTransactionCode(): string {
        const now = new Date();
        const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
        const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
        return `${BILLING_INVOICE_CONFIG.TRANSACTION_CODE_PREFIX}-${dateStr}-${rand}`;
    }

    // INVOICES

    /**
     * Tạo hóa đơn — nếu có encounter_id sẽ tự động gom phí khám + CLS + thuốc.
     * Nếu không có encounter_id thì tạo HĐ trống (thu ngân tự thêm items sau).
     */
    static async createInvoice(input: CreateInvoiceInput, userId: string): Promise<Invoice> {
        if (!input.patient_id) throw BILLING_INVOICE_ERRORS.MISSING_ENCOUNTER_OR_PATIENT;

        const patientExists = await BillingInvoiceRepository.checkPatientExists(input.patient_id);
        if (!patientExists) throw BILLING_INVOICE_ERRORS.PATIENT_NOT_FOUND;

        /* Nếu có encounter_id → delegate sang generate để tự gom items */
        if (input.encounter_id) {
            return await this.generateInvoiceFromEncounter(input.encounter_id, userId);
        }

        if (input.facility_id) {
            const facExists = await BillingInvoiceRepository.checkFacilityExists(input.facility_id);
            if (!facExists) throw BILLING_INVOICE_ERRORS.FACILITY_NOT_FOUND;
        }

        const invoiceId = this.generateId('INV');
        const invoiceCode = this.generateInvoiceCode();
        return await BillingInvoiceRepository.createInvoice(invoiceId, invoiceCode, input, userId);
    }

    /**
     * Tạo HĐ tự động từ encounter — gom: phí khám + CLS + thuốc
     * Đây là API "thông minh" nhất, tự động lấy dữ liệu từ EMR
     */
    static async generateInvoiceFromEncounter(encounterId: string, userId: string): Promise<Invoice> {
        const encounter = await BillingInvoiceRepository.getEncounterWithServices(encounterId);
        if (!encounter) throw BILLING_INVOICE_ERRORS.ENCOUNTER_NOT_FOUND;

        const existing = await BillingInvoiceRepository.getInvoiceByEncounterId(encounterId);
        if (existing) {
            return (await BillingInvoiceRepository.getInvoiceById(existing.invoices_id))!;
        }

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            /* 1. Tạo hóa đơn */
            const invoiceId = this.generateId('INV');
            const invoiceCode = this.generateInvoiceCode();
            const invoice = await BillingInvoiceRepository.createInvoice(invoiceId, invoiceCode, {
                patient_id: encounter.patient_id,
                encounter_id: encounterId,
                facility_id: encounter.facility_id || null,
            }, userId, client);

            /* Xác định tỷ lệ BHYT */
            const insurance = await BillingInvoiceRepository.getActiveInsurance(encounter.patient_id);
            const coveragePercent = insurance?.coverage_percent || insurance?.default_coverage || 0;

            /* 2. Thêm phí khám (CONSULTATION) */
            if (encounter.facility_services_id && encounter.consultation_price) {
                const price = parseFloat(encounter.consultation_price);
                const insuranceCovered = coveragePercent > 0 ? price * coveragePercent / 100 : 0;

                await BillingInvoiceRepository.addInvoiceItem(this.generateId('IDT'), invoiceId, {
                    reference_type: INVOICE_ITEM_TYPE.CONSULTATION,
                    reference_id: encounter.facility_services_id,
                    item_name: encounter.service_name || 'Phí khám bệnh',
                    quantity: 1,
                    unit_price: price,
                    insurance_covered: insuranceCovered,
                }, client);
            }

            /* 3. Thêm phí CLS (LAB_ORDER) — luôn thêm dù giá = 0 để tracking */
            const facilityId = encounter.facility_id || null;
            const orders = await BillingInvoiceRepository.getMedicalOrdersByEncounter(encounterId, facilityId);
            for (const order of orders) {
                const price = parseFloat(order.base_price || '0');
                const insuranceCovered = coveragePercent > 0 && price > 0 ? price * coveragePercent / 100 : 0;
                await BillingInvoiceRepository.addInvoiceItem(this.generateId('IDT'), invoiceId, {
                    reference_type: INVOICE_ITEM_TYPE.LAB_ORDER,
                    reference_id: order.medical_orders_id,
                    item_name: order.service_name || order.service_code,
                    quantity: 1,
                    unit_price: price,
                    insurance_covered: insuranceCovered,
                }, client);
            }

            /* 4. Thêm phí thuốc (DRUG) */
            const drugs = await BillingInvoiceRepository.getPrescriptionsByEncounter(encounterId, facilityId);
            for (const drug of drugs) {
                const unitPrice = parseFloat(drug.unit_price || '0');
                if (unitPrice > 0) {
                    const subtotal = drug.quantity * unitPrice;
                    const insuranceCovered = coveragePercent > 0 ? subtotal * coveragePercent / 100 : 0;
                    await BillingInvoiceRepository.addInvoiceItem(this.generateId('IDT'), invoiceId, {
                        reference_type: INVOICE_ITEM_TYPE.DRUG,
                        reference_id: drug.prescription_details_id,
                        item_name: drug.drug_name || 'Thuốc',
                        quantity: drug.quantity,
                        unit_price: unitPrice,
                        insurance_covered: insuranceCovered,
                    }, client);
                }
            }

            /* 5. Tính lại tổng tiền */
            const recalculated = await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);

            /* 6. Tạo claim BHYT nếu BN có BHYT */
            if (insurance && coveragePercent > 0) {
                const totalInsurance = parseFloat(recalculated.insurance_amount || '0');
                if (totalInsurance > 0) {
                    await BillingInvoiceRepository.createInsuranceClaim(
                        this.generateId('IIC'), invoiceId,
                        insurance.patient_insurances_id,
                        coveragePercent, totalInsurance, userId, client
                    );
                }
            }

            await client.query('COMMIT');

            /* Trả về HĐ chi tiết */
            return (await BillingInvoiceRepository.getInvoiceById(invoiceId))!;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /** Danh sách hóa đơn */
    static async getInvoices(
        facilityId?: string, patientId?: string, status?: string,
        dateFrom?: string, dateTo?: string, search?: string,
        page: number = BILLING_INVOICE_CONFIG.DEFAULT_PAGE,
        limit: number = BILLING_INVOICE_CONFIG.DEFAULT_LIMIT
    ): Promise<PaginatedResult<Invoice>> {
        const safeLimit = Math.min(limit, BILLING_INVOICE_CONFIG.MAX_LIMIT);
        return await BillingInvoiceRepository.getInvoices(facilityId, patientId, status, dateFrom, dateTo, search, page, safeLimit);
    }

    /** Chi tiết hóa đơn */
    static async getInvoiceById(invoiceId: string): Promise<Invoice> {
        const invoice = await BillingInvoiceRepository.getInvoiceById(invoiceId);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        return invoice;
    }

    /** Cập nhật hóa đơn */
    static async updateInvoice(invoiceId: string, input: UpdateInvoiceInput, userId: string): Promise<Invoice> {
        const invoice = await BillingInvoiceRepository.getInvoiceById(invoiceId);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        if (invoice.status === INVOICE_STATUS.CANCELLED) throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');
            await BillingInvoiceRepository.updateInvoice(invoiceId, input.discount_amount, input.notes, client);
            await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);
            /* Re-check paid status → detect OVERPAID */
            await BillingInvoiceRepository.updatePaidAmount(invoiceId, client);
            await client.query('COMMIT');
            return (await BillingInvoiceRepository.getInvoiceById(invoiceId))!;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /** Hủy hóa đơn */
    static async cancelInvoice(invoiceId: string, reason: string, userId: string): Promise<Invoice> {
        if (!reason) throw BILLING_INVOICE_ERRORS.CANCEL_REASON_REQUIRED;

        const invoice = await BillingInvoiceRepository.getInvoiceById(invoiceId);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        if (invoice.status === INVOICE_STATUS.CANCELLED) throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;

        /* Kiểm tra còn tiền chưa hoàn trả không */
        if (invoice.payments && invoice.payments.length > 0) {
            const totalPaid = invoice.payments
                .filter((p: PaymentTransaction) => p.status === PAYMENT_STATUS.SUCCESS && p.transaction_type === 'PAYMENT')
                .reduce((sum: number, p: PaymentTransaction) => sum + Number(p.amount || 0), 0);
            const totalRefunded = invoice.payments
                .filter((p: PaymentTransaction) => p.status === PAYMENT_STATUS.SUCCESS && p.transaction_type === 'REFUND')
                .reduce((sum: number, p: PaymentTransaction) => sum + Number(p.amount || 0), 0);
            // Chỉ block khi còn tiền chưa hoàn trả
            if (totalPaid - totalRefunded > 0) throw BILLING_INVOICE_ERRORS.INVOICE_HAS_PAYMENTS;
        }

        return await BillingInvoiceRepository.cancelInvoice(invoiceId, reason, userId);
    }

    /** Lấy HĐ theo encounter */
    static async getInvoiceByEncounter(encounterId: string): Promise<Invoice> {
        const enc = await BillingInvoiceRepository.checkEncounterExists(encounterId);
        if (!enc) throw BILLING_INVOICE_ERRORS.ENCOUNTER_NOT_FOUND;

        const invoice = await BillingInvoiceRepository.getInvoiceByEncounterId(encounterId);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;

        return (await BillingInvoiceRepository.getInvoiceById(invoice.invoices_id))!;
    }

    /** Lịch sử HĐ bệnh nhân */
    static async getInvoicesByPatient(
        patientId: string,
        page: number = BILLING_INVOICE_CONFIG.DEFAULT_PAGE,
        limit: number = BILLING_INVOICE_CONFIG.DEFAULT_LIMIT
    ): Promise<PaginatedResult<Invoice>> {
        const exists = await BillingInvoiceRepository.checkPatientExists(patientId);
        if (!exists) throw BILLING_INVOICE_ERRORS.PATIENT_NOT_FOUND;

        const safeLimit = Math.min(limit, BILLING_INVOICE_CONFIG.MAX_LIMIT);
        return await BillingInvoiceRepository.getInvoices(undefined, patientId, undefined, undefined, undefined, undefined, page, safeLimit);
    }

    // INVOICE DETAILS

    /** Thêm dòng chi tiết vào HĐ */
    static async addInvoiceItem(invoiceId: string, input: AddInvoiceItemInput, userId: string): Promise<InvoiceDetail> {
        const validTypes = Object.values(INVOICE_ITEM_TYPE);
        if (!validTypes.includes(input.reference_type as any)) throw BILLING_INVOICE_ERRORS.INVALID_ITEM_TYPE;
        if (input.quantity <= 0) throw BILLING_INVOICE_ERRORS.INVALID_QUANTITY;
        if (input.unit_price < 0) throw BILLING_INVOICE_ERRORS.INVALID_PRICE;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            /* Lock hóa đơn trước khi kiểm tra trạng thái */
            const invoice = await BillingInvoiceRepository.getInvoiceByIdWithLock(invoiceId, client);
            if (!invoice) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
            }
            if (invoice.status === INVOICE_STATUS.CANCELLED) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;
            }
            if (invoice.status === INVOICE_STATUS.PAID || invoice.status === 'OVERPAID') {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_ALREADY_PAID;
            }

            const itemId = this.generateId('IDT');
            const item = await BillingInvoiceRepository.addInvoiceItem(itemId, invoiceId, input, client);
            await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);
            await client.query('COMMIT');
            return item;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /** Sửa dòng chi tiết */
    static async updateInvoiceItem(invoiceId: string, itemId: string, input: UpdateInvoiceItemInput, userId: string): Promise<InvoiceDetail> {
        if (input.quantity !== undefined && input.quantity <= 0) throw BILLING_INVOICE_ERRORS.INVALID_QUANTITY;
        if (input.unit_price !== undefined && input.unit_price < 0) throw BILLING_INVOICE_ERRORS.INVALID_PRICE;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            /* Lock hóa đơn trước khi kiểm tra trạng thái */
            const invoice = await BillingInvoiceRepository.getInvoiceByIdWithLock(invoiceId, client);
            if (!invoice) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
            }
            if (invoice.status === INVOICE_STATUS.CANCELLED) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;
            }
            if (invoice.status === INVOICE_STATUS.PAID || invoice.status === 'OVERPAID') {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_ALREADY_PAID;
            }

            const existing = await BillingInvoiceRepository.getInvoiceItemById(itemId);
            if (!existing) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.ITEM_NOT_FOUND;
            }

            const item = await BillingInvoiceRepository.updateInvoiceItem(itemId, input, client);
            await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);
            await client.query('COMMIT');
            return item;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /** Xóa dòng chi tiết */
    static async deleteInvoiceItem(invoiceId: string, itemId: string, userId: string): Promise<void> {
        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            /* Lock hóa đơn trước khi kiểm tra trạng thái */
            const invoice = await BillingInvoiceRepository.getInvoiceByIdWithLock(invoiceId, client);
            if (!invoice) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
            }
            if (invoice.status === INVOICE_STATUS.CANCELLED) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;
            }
            if (invoice.status === INVOICE_STATUS.PAID || invoice.status === 'OVERPAID') {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.INVOICE_ALREADY_PAID;
            }

            const existing = await BillingInvoiceRepository.getInvoiceItemById(itemId);
            if (!existing) {
                await client.query('ROLLBACK');
                throw BILLING_INVOICE_ERRORS.ITEM_NOT_FOUND;
            }

            await BillingInvoiceRepository.deleteInvoiceItem(itemId, client);
            await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Tính lại tổng tiền HĐ thủ công
     * Sau khi tính lại → cập nhật paid status (detect OVERPAID)
     */
    static async recalculateInvoice(invoiceId: string): Promise<Invoice> {
        const invoice = await BillingInvoiceRepository.getInvoiceById(invoiceId);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        if (invoice.status === INVOICE_STATUS.CANCELLED) throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');
            await BillingInvoiceRepository.recalculateInvoice(invoiceId, client);
            /* Re-check paid status — có thể chuyển sang OVERPAID nếu paid > net mới */
            await BillingInvoiceRepository.updatePaidAmount(invoiceId, client);
            await client.query('COMMIT');
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }

        const result = (await BillingInvoiceRepository.getInvoiceById(invoiceId))!;

        /* Tính tiền thừa/thiếu để trả về cho thu ngân */
        const changeAmount = parseFloat(result.paid_amount) - parseFloat(result.net_amount);
        (result as any).change_amount = changeAmount > 0 ? changeAmount : 0;

        return result;
    }

    // PAYMENTS

    /**
     * Ghi nhận thanh toán — tạo transaction SUCCESS + cập nhật invoice
     */
    static async processPayment(input: CreatePaymentInput, cashierId: string): Promise<PaymentTransaction> {
        if (!VALID_PAYMENT_METHODS.includes(input.payment_method as any)) {
            throw BILLING_INVOICE_ERRORS.INVALID_PAYMENT_METHOD;
        }
        if (input.amount <= 0) throw BILLING_INVOICE_ERRORS.INVALID_AMOUNT;

        const invoice = await BillingInvoiceRepository.getInvoiceById(input.invoice_id);
        if (!invoice) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        if (invoice.status === INVOICE_STATUS.CANCELLED) throw BILLING_INVOICE_ERRORS.INVOICE_CANCELLED;
        if (invoice.status === INVOICE_STATUS.PAID) throw BILLING_INVOICE_ERRORS.INVOICE_ALREADY_PAID;

        /* Kiểm tra số tiền thanh toán không vượt quá số còn lại */
        const remaining = parseFloat(invoice.net_amount) - parseFloat(invoice.paid_amount);
        if (input.amount > remaining + 0.01) throw BILLING_INVOICE_ERRORS.OVERPAYMENT;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            const paymentId = this.generateId('TXN');
            const txnCode = this.generateTransactionCode();
            const payment = await BillingInvoiceRepository.createPayment(paymentId, txnCode, input, cashierId, client);

            /* Cập nhật paid_amount & status */
            await BillingInvoiceRepository.updatePaidAmount(input.invoice_id, client);

            await client.query('COMMIT');
            return payment;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /** Chi tiết giao dịch */
    static async getPaymentById(paymentId: string): Promise<PaymentTransaction> {
        const payment = await BillingInvoiceRepository.getPaymentById(paymentId);
        if (!payment) throw BILLING_INVOICE_ERRORS.PAYMENT_NOT_FOUND;
        return payment;
    }

    /** Giao dịch theo HĐ */
    static async getPaymentsByInvoice(invoiceId: string): Promise<PaymentTransaction[]> {
        const exists = await BillingInvoiceRepository.checkInvoiceExists(invoiceId);
        if (!exists) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;
        return await BillingInvoiceRepository.getPaymentsByInvoiceId(invoiceId);
    }

    /**
     * Hoàn tiền — tạo REFUND transaction + rollback paid_amount
     */
    static async processRefund(paymentId: string, input: RefundInput, cashierId: string): Promise<PaymentTransaction> {
        if (!input.refund_reason) throw BILLING_INVOICE_ERRORS.REASON_REQUIRED;
        if (input.amount <= 0) throw BILLING_INVOICE_ERRORS.INVALID_AMOUNT;

        const originalPayment = await BillingInvoiceRepository.getPaymentById(paymentId);
        if (!originalPayment) throw BILLING_INVOICE_ERRORS.PAYMENT_NOT_FOUND;
        if (originalPayment.status !== PAYMENT_STATUS.SUCCESS) throw BILLING_INVOICE_ERRORS.PAYMENT_NOT_SUCCESS;

        if (input.amount > parseFloat(originalPayment.amount)) throw BILLING_INVOICE_ERRORS.REFUND_EXCEEDS;

        const client = await BillingInvoiceRepository.getClient();
        try {
            await client.query('BEGIN');

            const refundId = this.generateId('TXN');
            const txnCode = this.generateTransactionCode();
            const refund = await BillingInvoiceRepository.createRefund(
                refundId, txnCode, originalPayment.invoice_id,
                input.amount, input.payment_method || originalPayment.payment_method,
                input.refund_reason, cashierId, client
            );

            /* Đánh dấu giao dịch gốc đã hoàn (nếu hoàn toàn bộ) */
            if (input.amount >= parseFloat(originalPayment.amount)) {
                await BillingInvoiceRepository.markPaymentRefunded(paymentId, client);
            }

            /* Cập nhật lại paid_amount & status */
            await BillingInvoiceRepository.updatePaidAmount(originalPayment.invoice_id, client);

            await client.query('COMMIT');
            return refund;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    // CASHIER SHIFTS

    /** Mở ca thu ngân */
    static async openShift(input: OpenShiftInput, cashierId: string): Promise<CashierShift> {
        if (input.opening_balance < 0) throw BILLING_INVOICE_ERRORS.INVALID_OPENING_BALANCE;

        /* Kiểm tra có ca đang mở chưa */
        const openShift = await BillingInvoiceRepository.getOpenShiftByCashier(cashierId);
        if (openShift) throw BILLING_INVOICE_ERRORS.SHIFT_ALREADY_OPEN;

        const shiftId = this.generateId('CSH');
        return await BillingInvoiceRepository.openShift(shiftId, cashierId, input.opening_balance, input.notes);
    }

    /** Đóng ca thu ngân */
    static async closeShift(shiftId: string, input: CloseShiftInput, cashierId: string): Promise<CashierShift> {
        const shift = await BillingInvoiceRepository.getShiftById(shiftId);
        if (!shift) throw BILLING_INVOICE_ERRORS.SHIFT_NOT_FOUND;
        if (shift.status !== 'OPEN') throw BILLING_INVOICE_ERRORS.SHIFT_ALREADY_CLOSED;

        /* Tính system balance = opening + tổng cash payments - cash refunds trong ca */
        const systemBalance = await BillingInvoiceRepository.calculateSystemBalance(shiftId);

        return await BillingInvoiceRepository.closeShift(shiftId, input.actual_closing_balance, systemBalance, input.notes);
    }

    /** Chi tiết ca */
    static async getShiftById(shiftId: string): Promise<CashierShift> {
        const shift = await BillingInvoiceRepository.getShiftById(shiftId);
        if (!shift) throw BILLING_INVOICE_ERRORS.SHIFT_NOT_FOUND;
        return shift;
    }

    /** Danh sách ca thu ngân */
    static async getShifts(
        cashierId?: string, status?: string, dateFrom?: string, dateTo?: string,
        page: number = BILLING_INVOICE_CONFIG.DEFAULT_PAGE,
        limit: number = BILLING_INVOICE_CONFIG.DEFAULT_LIMIT
    ): Promise<PaginatedResult<CashierShift>> {
        const safeLimit = Math.min(limit, BILLING_INVOICE_CONFIG.MAX_LIMIT);
        return await BillingInvoiceRepository.getShifts(cashierId, status, dateFrom, dateTo, page, safeLimit);
    }

    // STATISTICS & INSURANCE

    /** Thống kê doanh thu */
    static async getRevenueSummary(
        facilityId: string,
        dateFrom?: string,
        dateTo?: string
    ): Promise<RevenueSummary> {
        const exists = await BillingInvoiceRepository.checkFacilityExists(facilityId);
        if (!exists) throw BILLING_INVOICE_ERRORS.FACILITY_NOT_FOUND;
        return await BillingInvoiceRepository.getRevenueSummary(facilityId, dateFrom, dateTo);
    }

    /** Thông tin claim BHYT */
    static async getInsuranceClaim(invoiceId: string): Promise<InvoiceInsuranceClaim> {
        const exists = await BillingInvoiceRepository.checkInvoiceExists(invoiceId);
        if (!exists) throw BILLING_INVOICE_ERRORS.INVOICE_NOT_FOUND;

        const claim = await BillingInvoiceRepository.getInsuranceClaimByInvoice(invoiceId);
        if (!claim) throw { code: 'BIL_026', message: 'Hóa đơn này không có claim BHYT.' };
        return claim;
    }
}
