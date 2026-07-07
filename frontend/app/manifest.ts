import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "MenuMind — AI menu translator",
    short_name: "MenuMind",
    description:
      "Photograph any restaurant menu and get every dish translated, each with an AI-generated photo.",
    start_url: "/",
    display: "standalone",
    background_color: "#FFFBF7",
    theme_color: "#F05A28",
    orientation: "portrait",
    categories: ["food", "travel", "utilities"],
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
