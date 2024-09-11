const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/components/**/*.rb',
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      brightness: {
        25: '.25'
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'azure-radiance': {
          '50': '#eff6ff',
          '100': '#dae9ff',
          '200': '#bed9ff',
          '300': '#91c2ff',
          '400': '#5ea1fc',
          '500': '#3b7ef9',
          '600': '#225cee',
          '700': '#1a48db',
          '800': '#1c3bb1',
          '900': '#1c368c',
          '950': '#162255',
        },
        'bunker': {
          '50': '#f6f7f9',
          '100': '#eceff2',
          '200': '#d5dae2',
          '300': '#b1bcc8',
          '400': '#8697aa',
          '500': '#677a90',
          '600': '#526277',
          '700': '#434f61',
          '800': '#3a4552',
          '900': '#343b46',
          '950': '#171a1f',
        }
      },
    },
  }
}
