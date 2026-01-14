import { defineConfig, externalizeDepsPlugin } from 'electron-vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { viteStaticCopy } from 'vite-plugin-static-copy'
import { resolve } from 'path'

export default defineConfig({
  main: {
    plugins: [externalizeDepsPlugin()],
    build: {
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'electron/main.js')
        }
      }
    }
  },
  preload: {
    plugins: [externalizeDepsPlugin()],
    build: {
      rollupOptions: {
        input: {
          preload: resolve(__dirname, 'electron/preload.js')
        }
      }
    }
  },
  renderer: {
    root: resolve(__dirname, '../web'),
    build: {
      outDir: resolve(__dirname, 'out/renderer'),
      rollupOptions: {
        input: {
          index: resolve(__dirname, '../web/index.html')
        }
      }
    },
    plugins: [
      svelte(),
      viteStaticCopy({
        targets: [
          {
            // Copy PDF.js worker for offline use
            src: resolve(__dirname, '../../packages/core/node_modules/pdfjs-dist/build/pdf.worker.min.mjs'),
            dest: 'pdf-worker'
          }
        ]
      })
    ],
    resolve: {
      alias: {
        '@rsvp/core': resolve(__dirname, '../../packages/core/src')
      }
    },
    // Use relative paths for file:// protocol in production
    base: './'
  }
})
