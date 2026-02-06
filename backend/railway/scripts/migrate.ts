import 'dotenv/config';
import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function migrate() {
  console.log('Starting database migration...');

  const client = await pool.connect();

  try {
    // Create migrations table if it doesn't exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Get list of executed migrations
    const { rows: executedMigrations } = await client.query(
      'SELECT name FROM migrations ORDER BY id'
    );
    const executedNames = new Set(executedMigrations.map(m => m.name));

    // Read migration files
    const migrationsDir = path.join(__dirname, '../migrations');

    if (!fs.existsSync(migrationsDir)) {
      fs.mkdirSync(migrationsDir, { recursive: true });
      console.log('Created migrations directory');
    }

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    if (files.length === 0) {
      console.log('No migration files found. Running initial schema...');

      // Run initial schema
      const schemaPath = path.join(__dirname, '../../shared/db/schema.sql');
      if (fs.existsSync(schemaPath)) {
        const schema = fs.readFileSync(schemaPath, 'utf8');
        await client.query(schema);
        await client.query(
          'INSERT INTO migrations (name) VALUES ($1)',
          ['000_initial_schema.sql']
        );
        console.log('Initial schema applied successfully');
      } else {
        console.log('No schema.sql found, skipping initial schema');
      }

      return;
    }

    // Execute pending migrations
    for (const file of files) {
      if (executedNames.has(file)) {
        console.log(`Skipping ${file} (already executed)`);
        continue;
      }

      console.log(`Executing migration: ${file}`);
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');

      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query(
          'INSERT INTO migrations (name) VALUES ($1)',
          [file]
        );
        await client.query('COMMIT');
        console.log(`Migration ${file} completed successfully`);
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    }

    console.log('All migrations completed successfully');

  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate();
