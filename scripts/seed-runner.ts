/**
 * Seed runner — execute SQL seed files in databases/data/ in numerical order.
 * Files are idempotent (ON CONFLICT DO NOTHING).
 *
 * Usage:
 *   npm run seed:dev           → run 13_*.sql → 18_*.sql (new demo data files)
 *   npm run seed:dev:all       → run all 01_*.sql → 18_*.sql (incl. master data)
 *
 * Environment variables (read from .env if loaded):
 *   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
 */
import { Pool } from "pg";
import * as fs from "fs";
import * as path from "path";

const DATA_DIR = path.resolve(__dirname, "../databases/data");

async function main() {
    const all = process.argv.includes("--all");
    const minNum = all ? 1 : 13;
    const maxNum = 18;

    const pool = new Pool({
        host: process.env.DB_HOST ?? "localhost",
        port: parseInt(process.env.DB_PORT ?? "5432", 10),
        user: process.env.DB_USER ?? "postgres",
        password: process.env.DB_PASSWORD ?? "",
        database: process.env.DB_NAME ?? "ehealthdatabase",
    });

    const files = fs
        .readdirSync(DATA_DIR)
        .filter((f) => f.endsWith(".sql"))
        .filter((f) => {
            const m = f.match(/^(\d+)([a-z]?)_/);
            if (!m) return false;
            const num = parseInt(m[1], 10);
            return num >= minNum && num <= maxNum;
        })
        .sort();

    if (files.length === 0) {
        console.warn(`⚠ No seed files found in range ${minNum}-${maxNum}. Did you create them?`);
        await pool.end();
        return;
    }

    console.log(`▶ Running ${files.length} seed file(s) (range ${minNum}-${maxNum}):`);
    for (const f of files) {
        const sqlPath = path.join(DATA_DIR, f);
        const sql = fs.readFileSync(sqlPath, "utf8");
        process.stdout.write(`  → ${f} … `);
        const t0 = Date.now();
        try {
            await pool.query(sql);
            console.log(`OK (${Date.now() - t0}ms)`);
        } catch (e: any) {
            console.log(`FAIL: ${e.message}`);
            await pool.end();
            process.exit(1);
        }
    }
    await pool.end();
    console.log("✓ Done");
}

main().catch((e) => {
    console.error("Seed runner failed:", e);
    process.exit(1);
});
