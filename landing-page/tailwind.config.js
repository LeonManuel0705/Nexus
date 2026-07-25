export default {
  content: ['./src/**/*.html', './dist/**/*.html'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Radio Canada Big"', 'sans-serif'],
        body: ['"Inclusive Sans"', 'sans-serif'],
      },
      colors: {
        nexus: {
          purple: '#0057FF',
          pink: '#6BA1FF',
          blue: '#3D7BFF',
          text: '#1A202C',
          muted: '#64748B',
          surface: 'rgba(255,255,255,0.7)',
        }
      },
      backgroundImage: {
        'gradient-brand': 'linear-gradient(135deg, #0057FF 0%, #3D7BFF 50%, #6BA1FF 100%)',
        'gradient-subtle': 'linear-gradient(180deg, #FFFFFF 0%, #F8F7F4 100%)',
      },
      borderRadius: {
        'xl': '1rem',
        '2xl': '1.5rem',
        '3xl': '2rem',
      },
      boxShadow: {
        'glass': '0 8px 32px rgba(118, 75, 162, 0.1)',
        'soft': '0 4px 12px rgba(0, 0, 0, 0.05)',
      }
    }
  },
  plugins: [],
}
