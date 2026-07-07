export type ImageStatus = "pending" | "generating" | "ready" | "failed";

/**
 * Menu-level extraction status. The backend returns a placeholder immediately
 * with status "extracting" and fills in dishes in the background, so clients
 * must poll GET /menus/{id} until status becomes "ready" (or "failed").
 */
export type MenuStatus = "extracting" | "ready" | "failed";

export interface Nutrition {
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
}

export interface Dish {
  name_original: string;
  name_english: string;
  description_original: string;
  description_english: string;
  size: string;
  category: string;
  category_english: string;
  visual_appearance: string;
  price: string;
  dietary_tags?: string[];
  /** Engaging paragraph about the dish (backend field; filled by the 2nd pass). */
  about?: string;
  nutrition?: Nutrition | null;
  image_status: ImageStatus;
  image_url: string;
  image_error: string;
}

export interface Menu {
  id: string;
  source_language: string;
  restaurant_name: string | null;
  cuisine_type: string | null;
  dishes: Dish[];
  created_at: string;
  /** Absent on older backends — treat as "ready". */
  status?: MenuStatus;
}

export interface ApiError {
  error: string;
  message: string;
  request_id?: string;
}