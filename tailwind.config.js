/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./App.{js,jsx,ts,tsx}", "./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        knthlz: {
          dark: "#1a1a1a",
          surface: "#2b2b2b",
          green: "#ccff00", // Neon Green
          yellow: "#ffcc00", // Warning/Alert
          text: "#e0e0e0",
          dim: "#888888"
        }
      }
    },
  },
  plugins: [],
}
