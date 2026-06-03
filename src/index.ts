#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  Tool,
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { query, close } from "./db.js";

const server = new Server({
  name: "mcp-server-azure-postgres",
  version: "0.1.0",
});

const tools: Tool[] = [
  {
    name: "query",
    description:
      "Execute a SQL query. Use this to run any SQL statement against the Azure PostgreSQL database.",
    inputSchema: {
      type: "object" as const,
      properties: {
        sql: {
          type: "string",
          description: "The SQL query to execute",
        },
        params: {
          type: "array",
          description: "Optional parameters for parameterized queries ($1, $2, etc.)",
          items: {
            type: ["string", "number", "boolean", "null"],
          },
        },
      },
      required: ["sql"],
    },
  },
  {
    name: "list_schemas",
    description:
      "List all schemas in the PostgreSQL database",
    inputSchema: {
      type: "object" as const,
      properties: {},
      required: [],
    },
  },
  {
    name: "list_tables",
    description: "List all tables in a specific schema (default: public)",
    inputSchema: {
      type: "object" as const,
      properties: {
        schema: {
          type: "string",
          description: "The schema name (default: public)",
        },
      },
      required: [],
    },
  },
  {
    name: "describe_table",
    description:
      "Get detailed information about a table's columns (names, types, constraints)",
    inputSchema: {
      type: "object" as const,
      properties: {
        table: {
          type: "string",
          description: "The table name",
        },
        schema: {
          type: "string",
          description: "The schema name (default: public)",
        },
      },
      required: ["table"],
    },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result: any;

    switch (name) {
      case "query": {
        const { sql, params } = args as { sql: string; params?: any[] };
        result = await query(sql, params);
        return {
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case "list_schemas": {
        const result = await query(
          `SELECT schema_name FROM information_schema.schemata
           WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast', 'pg_temp_1')
           ORDER BY schema_name`
        );
        return {
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(
                result.rows.map((r: any) => r.schema_name),
                null,
                2
              ),
            },
          ],
        };
      }

      case "list_tables": {
        const { schema = "public" } = args as { schema?: string };
        const result = await query(
          `SELECT table_name FROM information_schema.tables
           WHERE table_schema = $1 AND table_type = 'BASE TABLE'
           ORDER BY table_name`,
          [schema]
        );
        return {
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(
                result.rows.map((r: any) => r.table_name),
                null,
                2
              ),
            },
          ],
        };
      }

      case "describe_table": {
        const { table, schema = "public" } = args as {
          table: string;
          schema?: string;
        };
        const result = await query(
          `SELECT column_name, data_type, is_nullable, column_default
           FROM information_schema.columns
           WHERE table_schema = $1 AND table_name = $2
           ORDER BY ordinal_position`,
          [schema, table]
        );
        return {
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(result.rows, null, 2),
            },
          ],
        };
      }

      default:
        return {
          content: [
            {
              type: "text" as const,
              text: `Unknown tool: ${name}`,
            },
          ],
        };
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [
        {
          type: "text" as const,
          text: `Error: ${errorMessage}`,
        },
      ],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP server running on stdio");
}

process.on("SIGINT", async () => {
  await close();
  process.exit(0);
});

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
