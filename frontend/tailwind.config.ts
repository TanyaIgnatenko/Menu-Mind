import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class"],
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    container: { center: true, padding: "2rem", screens: { "2xl": "1400px" } },
    extend: {
      // Desktop sidebar ↔ mobile-web switch (handoff breakpoint ~768–900px).
      screens: { nav: "860px" },
      fontFamily: {
        sans: ["var(--font-jakarta)", "system-ui", "sans-serif"],
        display: ["var(--font-jakarta)", "system-ui", "sans-serif"],
      },
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        navy: "hsl(var(--navy))",
        dill: "hsl(var(--dill))",
        coral: "hsl(var(--coral))",
        gold: "hsl(var(--gold))",
        // Hot Dish surfaces + text (web handoff tokens).
        ink: "hsl(var(--foreground))",
        body: "hsl(var(--muted-foreground))",
        "muted-2": "hsl(var(--muted-2))",
        canvas: "hsl(var(--canvas))",
        "canvas-alt": "hsl(var(--canvas-alt))",
        dropzone: "hsl(var(--dropzone-border))",
        success: {
          DEFAULT: "hsl(var(--success))",
          bg: "hsl(var(--success-bg))",
        },
        caution: {
          DEFAULT: "hsl(var(--caution))",
          bg: "hsl(var(--caution-bg))",
        },
        allergen: {
          DEFAULT: "hsl(var(--allergen))",
          bg: "hsl(var(--allergen-bg))",
        },
        category: {
          DEFAULT: "hsl(var(--category))",
          bg: "hsl(var(--category-bg))",
        },
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
          deep: "hsl(var(--primary-deep))",
          peach: "hsl(var(--primary-peach))",
          tint: "hsl(var(--primary-tint))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 4px)",
        sm: "calc(var(--radius) - 8px)",
      },
      boxShadow: {
        card: "0 2px 12px hsl(27 53% 7% / 0.08)",
        "card-hover": "0 8px 24px hsl(27 53% 7% / 0.12)",
        float: "0 12px 28px hsl(27 53% 7% / 0.14)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};
export default config;
