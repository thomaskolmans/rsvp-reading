import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { viteStaticCopy } from 'vite-plugin-static-copy'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    svelte(),
    viteStaticCopy({
      targets: [
        {
          // Copy PDF.js worker for offline use in Electron
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
  }
})
