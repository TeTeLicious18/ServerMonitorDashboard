/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gray: {
          900: '#0f1419',
          800: '#1a1f2e',
          700: '#252a3a',
          600: '#2d3748',
          500: '#4a5568',
          400: '#718096',
          300: '#a0aec0',
        }
      }
    },
  },
  plugins: [],
}
