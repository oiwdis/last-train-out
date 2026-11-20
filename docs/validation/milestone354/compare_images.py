"""Assemble paired, unretouched views from the packaged driver and art archives."""
import argparse
import csv
from io import BytesIO
from pathlib import Path
import zipfile

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat


LOCATIONS = ('harlow_platform', 'warehouse_a', 'warehouse_b', 'locomotive_cab', 'passenger_car',
             'curved_railway', 'ashford_depot', 'ashford_workshop', 'blackwater_crossing',
             'near_advancing_fog', 'inside_dangerous_fog', 'mission_completion')


def make_sheet(archive, pairs, group, output, rows):
    width, height, caption = 268, 151, 23
    pair_width = width * 2 + 12
    sheet = Image.new('RGB', (pair_width * 2, ((len(pairs) + 1) // 2) * (height + caption + 5) + 32), '#15191d')
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('DejaVuSans.ttf', 14)
    except OSError:
        font = ImageFont.load_default()
    draw.text((6, 9), f'{group}  |  Native Metal (left) and Vulkan (right) in each pair', fill='white', font=font)
    for index, (name, files) in enumerate(pairs):
        images = [Image.open(BytesIO(archive.read(file))).convert('RGB') for file in files]
        if images[0].size != images[1].size:
            raise ValueError(f'Mismatched capture size in {name}')
        x = (index % 2) * pair_width + 4
        y = (index // 2) * (height + caption + 5) + 32
        draw.text((x, y + 4), name.replace('_', ' '), fill='#f2ecdf', font=font)
        for offset, rendered in enumerate(images):
            sheet.paste(rendered.resize((width, height), Image.Resampling.LANCZOS), (x + offset * (width + 2), y + caption))
        differ = ImageStat.Stat(ImageChops.difference(*images))
        rows.append([group, name, *images[0].size, *[round(v, 3) for v in differ.mean],
                     *[round(ImageStat.Stat(image.convert('L')).mean[0], 3) for image in images]])
    sheet.save(output / (group.lower().replace(' ', '-') + '.jpg'), quality=91, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('drivers', type=Path)
    parser.add_argument('art', type=Path)
    parser.add_argument('output', type=Path)
    opt = parser.parse_args()
    opt.output.mkdir(parents=True, exist_ok=True)
    rows = []
    with zipfile.ZipFile(opt.drivers) as z:
        for index, preset in enumerate(('Low', 'Medium', 'High')):
            pairs = [(name, [f'{driver}-shots/{index}-{name}.png' for driver in ('metal', 'vulkan')]) for name in LOCATIONS]
            make_sheet(z, pairs, preset, opt.output, rows)
    with zipfile.ZipFile(opt.art) as z:
        names = sorted(Path(f).name for f in z.namelist() if f.startswith('metal/') and f.endswith('.png'))
        if len(names) != 17:
            raise ValueError(f'Expected 17 authored character, train and station views, found {len(names)}')
        for group, files in [('Character', names[:8]), ('Train and station', names[8:])]:
            pairs = [(Path(file).stem, [f'{driver}/{file}' for driver in ('metal', 'vulkan')]) for file in files]
            make_sheet(z, pairs, group, opt.output, rows)
    with (opt.output / 'pixel-comparison.csv').open('w', newline='') as stream:
        writer = csv.writer(stream, lineterminator='\n')
        writer.writerow(['group', 'view', 'width', 'height', 'mean_abs_red', 'mean_abs_green', 'mean_abs_blue',
                         'metal_mean_luma', 'vulkan_mean_luma'])
        writer.writerows(rows)


if __name__ == '__main__':
    main()
