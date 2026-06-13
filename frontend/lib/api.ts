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

// ── Custom error classes ──────────────────────────────────────────────────────

export class NotFoundError extends Error {
  constructor(message = "Not found") {
    super(message);
    this.name = "NotFoundError";
  }
}

/**
 * Thrown when the backend returns HTTP 429 with error "upload_limit_reached".
 *
 * Contains a human-readable `message` from the server and a `resetsAt` date
 * (always midnight UTC tonight) so the UI can tell the user exactly when
 * the limit resets without any extra API calls.
 */
export class UploadLimitError extends Error {
  /** UTC midnight of the next calendar day — when the limit resets. */
  readonly resetsAt: Date;

  constructor(message: string) {
    super(message);
    this.name = "UploadLimitError";

    // Limits reset at UTC midnight. Calculate it client-side: take now,
    // zero out the time component, add one day.
    const tomorrow = new Date();
    tomorrow.setUTCHours(24, 0, 0, 0); // next midnight UTC
    this.resetsAt = tomorrow;
  }
}

// ── Response handling ─────────────────────────────────────────────────────────

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let errorMessage = `Request failed: ${response.status}`;
    let errorCode = "";

    try {
      const error: ApiError = await response.json();
      errorMessage = error.message || errorMessage;
      errorCode = (error as { error?: string }).error ?? "";
    } catch {
      // Body wasn't JSON; keep generic message.
    }

    if (response.status === 404) {
      throw new NotFoundError(errorMessage);
    }

    if (response.status === 429 && errorCode === "upload_limit_reached") {
      throw new UploadLimitError(errorMessage);
    }

    throw new Error(errorMessage);
  }
  return response.json() as Promise<T>;
}

// ── API calls ─────────────────────────────────────────────────────────────────

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
