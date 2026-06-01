import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { SCHEMA_FILES } from "../src/load-order.js";

type Finding = {
  level: "error" | "warning";
  file: string;
  message: string;
};

const repoRoot = resolve(process.cwd());
const packageRoot = repoRoot.endsWith("agent-db-runtime")
  ? repoRoot
  : resolve(repoRoot, "packages/agent-db-runtime");

const findings: Finding[] = [];

const definePattern = /DEFINE\s+(?:TABLE|FIELD|INDEX|FUNCTION|EVENT)\s+([A-Za-z0-9_:.-]+)/gi;
const tablePattern = /DEFINE\s+TABLE\s+([A-Za-z0-9_:.-]+)/gi;
const fieldOnPattern = /DEFINE\s+FIELD\s+[A-Za-z0-9_:.-]+\s+ON\s+([A-Za-z0-9_:.-]+)/gi;
const relationPattern = /DEFINE\s+TABLE\s+([A-Za-z0-9_:.-]+)\s+TYPE\s+RELATION\s+IN\s+([A-Za-z0-9_:.-]+)\s+OUT\s+([A-Za-z0-9_:.-]+)/gi;

function push(level: Finding["level"], file: string, message: string): void {
  findings.push({ level, file, message });
}

function stripComments(input: string): string {
  return input
    .split("\n")
    .filter((line) => !line.trim().startsWith("--"))
    .join("\n");
}

function countChar(input: string, char: string): number {
  return [...input].filter((c) => c === char).length;
}

function collectMatches(pattern: RegExp, input: string): string[][] {
  pattern.lastIndex = 0;
  const matches: string[][] = [];
  let match: RegExpExecArray | null;

  while ((match = pattern.exec(input)) !== null) {
    matches.push([...match]);
  }

  return matches;
}

async function main(): Promise<void> {
  const definedTables = new Set<string>();
  const allDefinitions = new Map<string, string[]>();
  const fileContents = new Map<string, string>();

  console.log("Validating Agent DB Runtime schemas...\n");

  for (const file of SCHEMA_FILES) {
    const absolutePath = resolve(packageRoot, file);

    if (!existsSync(absolutePath)) {
      push("error", file, "Schema file is missing from load order.");
      continue;
    }

    const raw = await readFile(absolutePath, "utf8");
    const content = stripComments(raw);
    fileContents.set(file, content);

    const openBraces = countChar(content, "{");
    const closeBraces = countChar(content, "}");
    if (openBraces !== closeBraces) {
      push("error", file, `Unbalanced braces: ${openBraces} opening vs ${closeBraces} closing.`);
    }

    const openBrackets = countChar(content, "[");
    const closeBrackets = countChar(content, "]");
    if (openBrackets !== closeBrackets) {
      push("error", file, `Unbalanced brackets: ${openBrackets} opening vs ${closeBrackets} closing.`);
    }

    for (const [, table] of collectMatches(tablePattern, content)) {
      if (definedTables.has(table)) {
        push("warning", file, `Table '${table}' is defined more than once across schema files.`);
      }
      definedTables.add(table);
    }

    for (const [, definition] of collectMatches(definePattern, content)) {
      const files = allDefinitions.get(definition) ?? [];
      files.push(file);
      allDefinitions.set(definition, files);
    }
  }

  for (const [file, content] of fileContents.entries()) {
    for (const [, table] of collectMatches(fieldOnPattern, content)) {
      if (!definedTables.has(table)) {
        push("error", file, `Field references unknown table '${table}'.`);
      }
    }

    for (const [, relation, input, output] of collectMatches(relationPattern, content)) {
      if (!definedTables.has(input)) {
        push("error", file, `Relation '${relation}' references unknown IN table '${input}'.`);
      }
      if (!definedTables.has(output)) {
        push("error", file, `Relation '${relation}' references unknown OUT table '${output}'.`);
      }
    }

    const defineCount = collectMatches(definePattern, content).length;
    if (defineCount === 0) {
      push("warning", file, "No DEFINE statements found.");
    }

    if (content.includes("TODO") || content.includes("FIXME")) {
      push("warning", file, "Contains TODO/FIXME marker.");
    }
  }

  for (const [definition, files] of allDefinitions.entries()) {
    const uniqueFiles = [...new Set(files)];
    if (uniqueFiles.length > 1) {
      push("warning", uniqueFiles.join(", "), `Definition '${definition}' appears in multiple files.`);
    }
  }

  const errors = findings.filter((finding) => finding.level === "error");
  const warnings = findings.filter((finding) => finding.level === "warning");

  for (const file of SCHEMA_FILES) {
    if (existsSync(resolve(packageRoot, file))) {
      console.log(`✓ ${file}`);
    }
  }

  if (warnings.length > 0) {
    console.log("\nWarnings:");
    for (const warning of warnings) {
      console.log(`  ⚠ ${warning.file}: ${warning.message}`);
    }
  }

  if (errors.length > 0) {
    console.log("\nErrors:");
    for (const error of errors) {
      console.log(`  ✗ ${error.file}: ${error.message}`);
    }
    process.exitCode = 1;
    return;
  }

  console.log(`\nValidation complete: ${SCHEMA_FILES.length} files checked, ${warnings.length} warnings, 0 errors.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
