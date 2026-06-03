import { DefaultAzureCredential } from "@azure/identity";
import { Pool, PoolClient } from "pg";

const credential = new DefaultAzureCredential();
const SCOPE = "https://ossrdbms-aad.database.windows.net/.default";

export const pool = new Pool({
  host: process.env.PGHOST,
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  port: Number(process.env.PGPORT ?? 5432),
  ssl: { rejectUnauthorized: true },
  password: async () => {
    const { token } = await credential.getToken(SCOPE);
    return token;
  },
});

export async function query(text: string, values?: any[]) {
  return pool.query(text, values);
}

export async function getClient(): Promise<PoolClient> {
  return pool.connect();
}

export async function close(): Promise<void> {
  return pool.end();
}
