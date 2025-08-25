import type { Config } from 'tailwindcss'

const config: Config = {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
    '*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    container: { center: true, padding: '2rem', screens: { '2xl': '1400px' } },
    extend: {
      colors: {
        brand: {
          teal: '#5D8C87',   // secundario calm
          green: '#6BBFA0',  // acento/gradientes
          dark: '#262425',   // fondo principal
          red:  '#BF0F30',   // CTA
          blue: '#2C6DFF',   // acento para iconos / links secundarios
          white:'#FFFFFF',
        },
        background: '#262425',
        foreground: '#FFFFFF',
        border: '#343233',
        input:  '#343233',
        ring:   '#6BBFA0',

        primary: {
          DEFAULT: '#BF0F30',      // CTA rojo
          foreground: '#FFFFFF',
        },
        secondary: {
          DEFAULT: '#5D8C87',      // headings secundarios, chips
          foreground: '#262425',
        },
        accent: {
          DEFAULT: '#6BBFA0',      // acentos / highlights / badges
          foreground: '#262425',
        },
        muted: {
          DEFAULT: '#2B292A',
          foreground: 'rgba(255,255,255,0.80)', // texto cuerpo
        },
        popover: {
          DEFAULT: '#262425',
          foreground: '#FFFFFF',
        },
        card: {
          DEFAULT: '#262425',
          foreground: '#FFFFFF',
        },
      },
      boxShadow: {
        brand: '0 10px 30px -10px rgba(107,191,160,.35)', // glow verde
      },
      borderRadius: {
        lg: '0.75rem',
        md: '0.6rem',
        sm: '0.45rem',
      },
      backgroundImage: {
        // De oscuro (se integra con el nav) a verde corporativo
        'hero-gradient':
          'linear-gradient(to bottom, #262425 0%, #262425 15%, #4e7a75 40%, #6BBFA0 100%)',

        // Variante un poco más oscura (por si una foto de fondo es muy clara)
        'hero-gradient-deep':
          'linear-gradient(to bottom, rgba(38,36,37,0.95) 0%, #3f6561 32%, #5D8C87 100%)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
}
export default config
