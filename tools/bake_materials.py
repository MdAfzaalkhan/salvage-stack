#!/usr/bin/env python3
"""Bake exact-contour materials exported by Godot; Python stdlib, no runtime shaders.

1. godot --headless --path . --script res://tools/export_material_shapes.gd
2. python3 tools/bake_materials.py

RGBA is zero outside the collision union. A chamfer distance field supplies
bevel normals; Blinn-Phong edge reflection, darker side/lower facets and small
interior caustics are baked inside that silhouette at three texels/world unit.
"""
import json, math, struct, zlib
from array import array
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/materials'
SCALE=3

def write_png(path,w,h,rgba):
    def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    raw=b''.join(b'\0'+rgba[y*w*4:(y+1)*w*4] for y in range(h))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,8))+chunk(b'IEND',b''))

def raster(s):
    w=round(s['w']*SCALE);h=round(s['h']*SCALE)
    mask=bytearray(w*h)
    for y in range(h):
        yy=(y+.5)/SCALE-s['h']/2
        for poly in s['contours']:
            crosses=[]
            for i,(x1,y1) in enumerate(poly):
                x2,y2=poly[(i+1)%len(poly)]
                if (y1<=yy<y2) or (y2<=yy<y1):crosses.append(x1+(yy-y1)*(x2-x1)/(y2-y1))
            crosses.sort()
            for k in range(0,len(crosses)-1,2):
                a=max(0,math.ceil((crosses[k]+s['w']/2)*SCALE-.5))
                b=min(w,math.ceil((crosses[k+1]+s['w']/2)*SCALE-.5))
                mask[y*w+a:y*w+b]=b'\1'*(b-a)
    bevel=(4.8 if s['number'] else (2.3 if s['surface'] else 3.6))*SCALE
    far=bevel+2
    d=array('f',(far if x else 0. for x in mask))
    diagonal=math.sqrt(2)
    for y in range(h):
        row=y*w
        for x in range(w):
            i=row+x
            if not mask[i]:continue
            t=d[i]
            if x==0 or y==0:t=min(t,.5)
            if x:t=min(t,d[i-1]+1)
            if y:t=min(t,d[i-w]+1)
            if x and y:t=min(t,d[i-w-1]+diagonal)
            if x<w-1 and y:t=min(t,d[i-w+1]+diagonal)
            d[i]=t
    for y in range(h-1,-1,-1):
        row=y*w
        for x in range(w-1,-1,-1):
            i=row+x
            if not mask[i]:continue
            t=d[i]
            if x==w-1 or y==h-1:t=min(t,.5)
            if x<w-1:t=min(t,d[i+1]+1)
            if y<h-1:t=min(t,d[i+w]+1)
            if x<w-1 and y<h-1:t=min(t,d[i+w+1]+diagonal)
            if x and y<h-1:t=min(t,d[i+w-1]+diagonal)
            d[i]=t
    number=s['number']
    base=[(64,73,94),(176,93,8),(145,22,92),(12,116,148)][number]
    tint=[(174,190,222),(255,190,58),(255,88,176),(68,221,248)][number]
    if s['surface']:base=(37,43,57);tint=(112,126,150)
    rgba=bytearray(w*h*4)
    for y in range(h):
        v=(y+.5)/h
        for x in range(w):
            i=y*w+x
            if not mask[i]:continue
            distance=d[i]
            gx=(d[i+1] if x<w-1 else 0)-(d[i-1] if x else 0)
            gy=(d[i+w] if y<h-1 else 0)-(d[i-w] if y else 0)
            length=math.hypot(gx,gy)
            t=min(1,distance/bevel)
            angle=t*math.pi*.5
            side=math.cos(angle)
            nx=-gx/length*side if length else 0
            ny=-gy/length*side if length else 0
            nz=math.sin(angle) if length else 1
            light=max(0,-nx*.48-ny*.62+nz*.65)
            spec=max(0,-nx*.25-ny*.32+nz*.913)**(24 if number else 40)
            u=(x+.5)/w
            ambient=.45+.68*light
            soft=.045*math.exp(-(((u-.28)/.55)**2+((v-.28)/.6)**2)*2)
            ambient+=soft
            # Wide, irregular studio reflections: cloudy depth, not a flat ramp.
            cloud=math.exp(-(((u-.26)/.28)**2+((v-.31)/.42)**2)*2)
            hollow=math.exp(-(((u-.62)/.32)**2+((v-.62)/.38)**2)*2)
            ambient+=.12*cloud-.10*hollow
            if number:
                # Thin inner refractions, never a broad diagonal stripe.
                caustic=max(0,1-abs(u-.18)/.015)*math.sin(v*math.pi)*.09
                caustic+=max(0,1-abs(u-.79)/.01)*math.sin(v*math.pi)*.12
                caustic+=.13*math.exp(-((v-.83)/.024)**2)*math.sin(u*math.pi)
                caustic+=.20*math.exp(-(((u-.17)/.055)**2+((v-.15)/.055)**2))
            else:caustic=.015*math.exp(-((v-.2)/.07)**2)
            rim=max(0,1-distance/(.85*SCALE))
            edge_light=.23+.50*max(0,-ny)+.20*max(0,-nx)
            lower=max(0,ny)*max(0,1-t)*.30
            # An inset face line provides controlled thickness behind the edge.
            inset=max(0,1-abs(distance-bevel*.92)/(SCALE*.45))*.07
            for c in range(3):
                color=base[c]*max(.18,ambient-lower)
                color+=tint[c]*(spec*(.65 if number else .58)+rim*edge_light*.65+caustic+inset)
                rgba[i*4+c]=round(max(0,min(255,color)))
            rgba[i*4+3]=255
    return w,h,rgba

if __name__=='__main__':
    shapes=json.loads((ROOT/'shapes.json').read_text())
    previews=[];seen=set()
    for i,s in enumerate(shapes):
        w,h,rgba=raster(s);write_png(ROOT/s['file'],w,h,rgba)
        category=(s['key'].split('|')[0],s['number'])
        if category not in seen and (s['key'].startswith('slab|200.000|30.000') or s['key'].startswith('bridge|180.000|84.000') or s['key'].startswith('core|42.000|42.000')):
            previews.append((s,w,h,rgba));seen.add(category)
        if (i+1)%10==0:print('Baked',i+1,'/',len(shapes),flush=True)
    # Production-asset inspection sheet, explicitly not a running-game image.
    sw,sh=900,580;sheet=bytearray(bytes((8,9,14,255))*(sw*sh))
    for k,(s,w,h,pixels) in enumerate(previews):
        ox=40 if not s['number'] else 550+(s['number']-1)*110
        oy=60 if s['key'].startswith('slab') else (220 if not s['number'] else 390)
        f=min(1,450/w,200/h) if not s['number'] else .75
        for yy in range(int(h*f)):
            for xx in range(int(w*f)):
                at=((int(oy)+yy)*sw+int(ox)+xx)*4;src=(int(yy/f)*w+int(xx/f))*4
                if 0<=at<len(sheet)-3 and pixels[src+3]:sheet[at:at+4]=pixels[src:src+4]
    write_png(ROOT.parents[1]/'docs/material-sheet.png',sw,sh,sheet)
    print('Baked all',len(shapes),'exact-contour material textures.',flush=True)
