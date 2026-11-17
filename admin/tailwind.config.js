/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#EEF2FF',
          100: '#E0E7FF',
          200: '#C7D2FE',
          300: '#A5B4FC',
          400: '#818CF8',
          500: '#6366F1',
          600: '#4F46E5', // Primary indigo button
          700: '#4338CA',
          800: '#3730A3',
          900: '#312E81',
        },
        surface: {
          canvas: '#0B0F19',
          sidebar: '#0D121E',
          card: '#151B2C',
          elevated: '#1B2237',
          elevated2: '#212942',
        },
        guardian: {
          bg: 'var(--bg-canvas)',
          sidebar: 'var(--bg-sidebar)',
          card: 'var(--bg-card)',
          cardElevated: 'var(--bg-card-elevated)',
          cardElevated2: 'var(--bg-card-elevated2)',
          border: 'var(--border-color)',
          borderHover: 'var(--border-hover-color)',
          text: 'var(--text-primary)',
          muted: 'var(--text-secondary)',
          dimmed: 'var(--text-muted)',
          accent: '#38BDF8',
          success: '#10B981',
          warning: '#F59E0B',
          critical: '#EF4444',
          info: '#3B82F6',
        },
      },
      borderRadius: {
        xl: '12px',
        lg: '8px',
        md: '6px',
        sm: '4px',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'Consolas', 'monospace'],
      },
    },
  },
  plugins: [],
};
