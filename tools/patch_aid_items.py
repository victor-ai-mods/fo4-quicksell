"""
Правка QuickSell.esp для v1.5: предметы Aid перестают выглядеть как стимпак.

Все три предмета (Sell Mode Switch, Mobile Barter Beacon, QuickSell Configurator)
сделаны в Creation Kit копией ванильного Stimpak и унаследовали его ключевые слова
PlayAnimOnItemUse (00184C3D) и ObjectTypeStimpak (000F4AEB) и звук применения
NPCHumanChemsStimpak. Игра и моды, которые реагируют на стимпаки и анимации
применения, перехватывают такое «использование», и скрипт эффекта не запускается
(баг-репорт «QuickSell Configurator» на Nexus: клавиши работают, предметы — нет).

Что делает:
  * у трёх ALCH убирает KSIZ/KWDA и обнуляет звук применения в ENIT;
  * удаляет случайную правку ванильного MGEF HC_QuantumAPDescription (00249F9F);
  * переименовывает QS_ConfigMenuMGEF («Instantly restores AP», скопировано
    с того же ванильного эффекта) в «QuickSell Configurator».

Идемпотентно: повторный запуск ничего не меняет.

  python tools/patch_aid_items.py [путь к esp]   (по умолчанию QuickSell.esp в корне)
"""

import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

AID_ITEMS = {0x01001ED9, 0x01001EDD, 0x01002E15}
DROP_RECORDS = {0x00249F9F}
RENAME = {0x01002E17: b'QuickSell Configurator\x00'}

COMPRESSED = 0x00040000


def subrecords(body):
    out = []
    pos = 0
    while pos < len(body):
        tag = body[pos:pos + 4]
        size = struct.unpack_from('<H', body, pos + 4)[0]
        if tag == b'XXXX':
            raise ValueError('XXXX в записи, которую правим, не ожидался')
        out.append((tag, body[pos + 6:pos + 6 + size]))
        pos += 6 + size
    return out


def pack_subrecords(subs):
    return b''.join(tag + struct.pack('<H', len(data)) + data for tag, data in subs)


def patch_record(form_id, body):
    subs = subrecords(body)
    if form_id in AID_ITEMS:
        new = []
        for tag, data in subs:
            if tag in (b'KSIZ', b'KWDA'):
                continue
            if tag == b'ENIT':
                # value, flags, addiction, addiction chance, consume sound
                data = data[:16] + b'\x00\x00\x00\x00'
            new.append((tag, data))
        subs = new
    if form_id in RENAME:
        subs = [(t, RENAME[form_id] if t == b'FULL' else d) for t, d in subs]
    return pack_subrecords(subs)


def rewrite(buf, start, end, stats):
    """Переписывает записи и группы в [start, end); возвращает новые байты."""
    out = []
    pos = start
    while pos < end:
        sig = buf[pos:pos + 4]
        size = struct.unpack_from('<I', buf, pos + 4)[0]
        if sig == b'GRUP':
            inner = rewrite(buf, pos + 24, pos + size, stats)
            header = bytearray(buf[pos:pos + 24])
            struct.pack_into('<I', header, 4, 24 + len(inner))
            out.append(bytes(header) + inner)
            pos += size
            continue
        flags, form_id = struct.unpack_from('<II', buf, pos + 8)
        record = buf[pos:pos + 24 + size]
        pos += 24 + size
        if form_id in DROP_RECORDS:
            stats['dropped'] += 1
            continue
        if form_id in AID_ITEMS or form_id in RENAME:
            if flags & COMPRESSED:
                raise ValueError('сжатая запись %08X — не ожидалась' % form_id)
            body = patch_record(form_id, record[24:])
            header = bytearray(record[:24])
            struct.pack_into('<I', header, 4, len(body))
            record = bytes(header) + body
            stats['patched'] += 1
        out.append(record)
    return b''.join(out)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'QuickSell.esp')
    buf = open(path, 'rb').read()
    tes4_size = struct.unpack_from('<I', buf, 4)[0]
    tes4 = bytearray(buf[:24 + tes4_size])
    stats = {'dropped': 0, 'patched': 0}
    rest = rewrite(buf, len(tes4), len(buf), stats)
    if stats['dropped']:
        # HEDR: version(f32), numRecords(u32), nextObjectId(u32)
        hedr = tes4.find(b'HEDR', 24)
        count = struct.unpack_from('<I', tes4, hedr + 10)[0]
        struct.pack_into('<I', tes4, hedr + 10, count - stats['dropped'])
    new = bytes(tes4) + rest
    if new == buf:
        print('без изменений: %s' % path)
        return
    open(path, 'wb').write(new)
    print('%s: изменено записей %d, удалено %d, %d -> %d байт'
          % (path, stats['patched'], stats['dropped'], len(buf), len(new)))


if __name__ == '__main__':
    main()
