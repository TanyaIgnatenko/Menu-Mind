import type { ApiError, Menu } from "./types";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

// Image URLs returned by the backend are relative paths like "/images/abc/0.jpg".
// They are served by the same FastAPI app (NOT under /api/v1), so we build them
// against the backend root.
const BACKEND_ROOT = API_BASE.replace(/\/api\/v1\/?$/, "");

export function imageUrl(relativePath: string): string {
  if (!relativePath) return "";
  if (relativePath.startsWith("http")) return relativePath;
  return `${BACKEND_ROOT}${relativePath}`;
}

export class NotFoundError extends Error {
  constructor(message = "Not found") {
    super(message);
    this.name = "NotFoundError";
  }
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let errorMessage = `Request failed: ${response.status}`;
    try {
      const error: ApiError = await response.json();
      errorMessage = error.message || errorMessage;
    } catch {
      // Body wasn't JSON; keep generic message.
    }
    if (response.status === 404) {
      throw new NotFoundError(errorMessage);
    }
    throw new Error(errorMessage);
  }
  return response.json() as Promise<T>;
}

export async function uploadMenu(file: File): Promise<Menu> {
  const formData = new FormData();
  formData.append("file", file);

  const response = await fetch(`${API_BASE}/menus/`, {
    method: "POST",
    body: formData,
  });

  return handleResponse<Menu>(response);
}

export async function getMenu(menuId: string): Promise<Menu> {
  const response = await fetch(`${API_BASE}/menus/${menuId}`);
  return handleResponse<Menu>(response);
}