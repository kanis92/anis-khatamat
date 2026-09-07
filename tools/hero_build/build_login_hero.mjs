#!/usr/bin/env node
/**
 * Deterministic derived login hero from assets/images/anis_header.png
 * No AI — uniform scale + canvas extension + background feather only.
 */
import sharp from 'sharp';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '../..');
const SOURCE = join(ROOT, 'assets/images/anis_header.png');
const OUTPUT = join(ROOT, 'assets/branding/anis_login_hero.png');

/** Uniform scale — artwork ~18% smaller than prior full-bleed (mid of 15–22%). */
const ARTWORK_SCALE = 0.82;

/** Visual center of gravity target on final canvas (fraction of width). */
const CENTER_X_RATIO = 0.62;

/** Extra canvas width vs scaled artwork (mostly left emerald). */
const LEFT_EXTEND_RATIO = 0.38;

/** Vertical placement: fraction from top of canvas (0.5 = centered). */
const CENTER_Y_RATIO = 0.52;

/** Feather strip width for background seam (px, on source resolution scale). */
const FEATHER_PX = 48;

function rgbDist(a, b) {
  return Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2);
}

async function main() {
  const srcMeta = await sharp(SOURCE).metadata();
  const srcW = srcMeta.width;
  const srcH = srcMeta.height;
  console.log('SOURCE', SOURCE);
  console.log('SOURCE_DIM', `${srcW}x${srcH}`);
  console.log('SOURCE_ASPECT', (srcW / srcH).toFixed(4));

  const { data, info } = await sharp(SOURCE)
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const channels = info.channels;
  const w = info.width;
  const h = info.height;

  const bg = [data[0], data[1], data[2]];
  let minX = w,
    minY = h,
    maxX = 0,
    maxY = 0,
    sumX = 0,
    count = 0;

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const i = (y * w + x) * channels;
      const px = [data[i], data[i + 1], data[i + 2]];
      if (rgbDist(px, bg) > 12) {
        minX = Math.min(minX, x);
        maxX = Math.max(maxX, x);
        minY = Math.min(minY, y);
        maxY = Math.max(maxY, y);
        sumX += x;
        count++;
      }
    }
  }

  const contentCx = sumX / count;
  const contentCy = (minY + maxY) / 2;
  console.log('CONTENT_BBOX', minX, minY, maxX, maxY);
  console.log('CONTENT_CENTER', contentCx.toFixed(1), contentCy.toFixed(1));

  const scaledW = Math.round(srcW * ARTWORK_SCALE);
  const scaledH = Math.round(srcH * ARTWORK_SCALE);

  const scaledBuf = await sharp(SOURCE)
    .resize(scaledW, scaledH, { kernel: sharp.kernel.lanczos3 })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const leftExtend = Math.round(scaledW * LEFT_EXTEND_RATIO);
  const canvasW = leftExtend + scaledW + Math.round(scaledW * 0.06);
  const canvasH = scaledH;

  const scaledContentCx = contentCx * ARTWORK_SCALE;
  const targetCx = canvasW * CENTER_X_RATIO;
  let pasteX = Math.round(targetCx - scaledContentCx);
  pasteX = Math.max(leftExtend - Math.round(scaledW * 0.08), pasteX);
  const pasteY = Math.round(canvasH * CENTER_Y_RATIO - (contentCy * ARTWORK_SCALE));

  // Sample emerald from left edge columns of source.
  const samples = [];
  for (let y = 0; y < h; y += 4) {
    for (let x = 0; x < 8; x++) {
      const i = (y * w + x) * channels;
      samples.push([data[i], data[i + 1], data[i + 2]]);
    }
  }
  const fill = samples.reduce(
    (acc, c) => [acc[0] + c[0], acc[1] + c[1], acc[2] + c[2]],
    [0, 0, 0],
  ).map((v) => Math.round(v / samples.length));

  console.log('FILL_RGB', fill);

  const canvas = Buffer.alloc(canvasW * canvasH * 4);
  for (let y = 0; y < canvasH; y++) {
    for (let x = 0; x < canvasW; x++) {
      const i = (y * canvasW + x) * 4;
      // Subtle vertical gradient on extended emerald (sample variation).
      const t = y / canvasH;
      canvas[i] = Math.min(255, Math.round(fill[0] * (0.98 + t * 0.04)));
      canvas[i + 1] = Math.min(255, Math.round(fill[1] * (0.98 + t * 0.03)));
      canvas[i + 2] = Math.min(255, Math.round(fill[2] * (0.98 + t * 0.02)));
      canvas[i + 3] = 255;
    }
  }

  const sData = scaledBuf.data;
  const sChannels = scaledBuf.info.channels;
  const sW = scaledBuf.info.width;
  const sH = scaledBuf.info.height;

  for (let y = 0; y < sH; y++) {
    const cy = y + pasteY;
    if (cy < 0 || cy >= canvasH) continue;
    for (let x = 0; x < sW; x++) {
      const cx = x + pasteX;
      if (cx < 0 || cx >= canvasW) continue;
      const si = (y * sW + x) * sChannels;
      const di = (cy * canvasW + cx) * 4;
      const sr = sData[si];
      const sg = sData[si + 1];
      const sb = sData[si + 2];
      const sa = sChannels === 4 ? sData[si + 3] : 255;

      const isBg = rgbDist([sr, sg, sb], bg) < 14;
      const inFeather = cx - pasteX < FEATHER_PX && isBg;
      const alpha = sa / 255;

      if (inFeather) {
        const t = Math.max(0, Math.min(1, (cx - pasteX) / FEATHER_PX));
        const smooth = t * t * (3 - 2 * t);
        canvas[di] = Math.round(canvas[di] * (1 - smooth) + sr * smooth);
        canvas[di + 1] = Math.round(canvas[di + 1] * (1 - smooth) + sg * smooth);
        canvas[di + 2] = Math.round(canvas[di + 2] * (1 - smooth) + sb * smooth);
        canvas[di + 3] = 255;
      } else {
        const outA = alpha + (canvas[di + 3] / 255) * (1 - alpha);
        if (outA <= 0) continue;
        canvas[di] = Math.round((sr * alpha + canvas[di] * (canvas[di + 3] / 255) * (1 - alpha)) / outA);
        canvas[di + 1] = Math.round((sg * alpha + canvas[di + 1] * (canvas[di + 3] / 255) * (1 - alpha)) / outA);
        canvas[di + 2] = Math.round((sb * alpha + canvas[di + 2] * (canvas[di + 3] / 255) * (1 - alpha)) / outA);
        canvas[di + 3] = Math.round(outA * 255);
      }
    }
  }

  mkdirSync(dirname(OUTPUT), { recursive: true });
  await sharp(canvas, { raw: { width: canvasW, height: canvasH, channels: 4 } })
    .png({ compressionLevel: 6 })
    .toFile(OUTPUT);

  const outMeta = await sharp(OUTPUT).metadata();
  console.log('OUTPUT', OUTPUT);
  console.log('OUTPUT_DIM', `${outMeta.width}x${outMeta.height}`);
  console.log('ARTWORK_SCALE', ARTWORK_SCALE);
  console.log('PASTE_X', pasteX, 'PASTE_Y', pasteY);
  console.log('CENTER_X_RATIO_ACTUAL', ((pasteX + scaledContentCx) / canvasW).toFixed(3));
  console.log('LEFT_EXTEND_PX', leftExtend);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
