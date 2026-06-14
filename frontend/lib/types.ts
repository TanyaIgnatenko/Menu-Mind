export type ImageStatus = "pending" | "generating" | "ready" | "failed";

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
}

export interface ApiError {
  error: string;
  message: string;
  request_id?: string;
}