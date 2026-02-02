export type Pixel = {
  id: string;
  canvas_id: string;
  user_id: string;
  x: number;
  y: number;
  color: string;
  created_at: string;
  name?: string;
  profiles?: {
    id: string;
    full_name?: string;
    avatar_url?: string;
  };
};
