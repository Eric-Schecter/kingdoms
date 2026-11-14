from pathlib import Path
import hashlib,json,zipfile
web=Path('build/web')
pack=web/'index.pck'
name='game-'+hashlib.sha256(pack.read_bytes()).hexdigest()[:12]+'.pck'
for old in web.glob('game-*.pck'): old.unlink()
pack.rename(web/name)
html=web/'index.html'
html.write_text(html.read_text().replace('const canvas=', 'config.mainPack='+json.dumps(name)+';\nconst canvas=',1))
with zipfile.ZipFile('build/Kingdoms-Web.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(web.iterdir()):
  if p.is_file(): z.write(p,p.name)
print('Web bundle:',name)
