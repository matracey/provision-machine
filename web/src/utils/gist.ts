import { REPO_API_URL, REPO_FILES } from "./constants";
import { serializeJson, serializeYaml } from "./fileIO";
import type { YamlConfig } from "../types";

interface SaveToRepoOptions {
  pat: string;
  json: Record<string, unknown> | null;
  yamlWork: YamlConfig | null;
  yamlPersonal: YamlConfig | null;
}

interface FileToCommit {
  path: string;
  content: string;
}

async function getFileSha(pat: string, path: string): Promise<string | null> {
  const response = await fetch(`${REPO_API_URL}/contents/${path}`, {
    headers: {
      Authorization: `token ${pat}`,
      Accept: "application/vnd.github.v3+json",
    },
  });
  if (!response.ok) return null;
  const data = await response.json();
  return data.sha ?? null;
}

async function commitFile(
  pat: string,
  path: string,
  content: string,
  message: string,
): Promise<void> {
  const sha = await getFileSha(pat, path);
  const body: Record<string, unknown> = {
    message,
    content: btoa(unescape(encodeURIComponent(content))),
  };
  if (sha) body.sha = sha;

  const response = await fetch(`${REPO_API_URL}/contents/${path}`, {
    method: "PUT",
    headers: {
      Authorization: `token ${pat}`,
      "Content-Type": "application/json",
      Accept: "application/vnd.github.v3+json",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.message || `HTTP ${response.status}`);
  }
}

export async function saveToRepo({
  pat,
  json,
  yamlWork,
  yamlPersonal,
}: SaveToRepoOptions): Promise<void> {
  const files: FileToCommit[] = [];

  if (json) {
    files.push({ path: REPO_FILES.json, content: serializeJson(json) });
  }

  if (yamlWork) {
    files.push({ path: REPO_FILES.yamlWork, content: serializeYaml(yamlWork) });
  }

  if (yamlPersonal) {
    files.push({
      path: REPO_FILES.yamlPersonal,
      content: serializeYaml(yamlPersonal),
    });
  }

  if (files.length === 0) {
    throw new Error("No files loaded to save");
  }

  for (const file of files) {
    const name = file.path.split("/").pop();
    await commitFile(
      pat,
      file.path,
      file.content,
      `chore: update ${name} via config editor`,
    );
  }
}
