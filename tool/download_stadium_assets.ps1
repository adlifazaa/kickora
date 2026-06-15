# Downloads Wikimedia Commons stadium photos into assets/stadiums/ (CC-licensed).
$ErrorActionPreference = 'Continue'
$outDir = Join-Path $PSScriptRoot '..\assets\stadiums'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$downloads = @{
  'metlife.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/MetLife_Stadium_-_Night.jpg/640px-MetLife_Stadium_-_Night.jpg'
  'att.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/AT%26T_Stadium_-_Night.jpg/640px-AT%26T_Stadium_-_Night.jpg'
  'sofi.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/SoFi_Stadium_interior_view.jpg/640px-SoFi_Stadium_interior_view.jpg'
  'mercedes_benz.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Mercedes-Benz_Stadium_%28Atlanta%29.jpg/640px-Mercedes-Benz_Stadium_%28Atlanta%29.jpg'
  'hard_rock.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Hard_Rock_Stadium_2019.jpg/640px-Hard_Rock_Stadium_2019.jpg'
  'nrg.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/NRG_Stadium_Houston.jpg/640px-NRG_Stadium_Houston.jpg'
  'lincoln_financial.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Lincoln_Financial_Field_outside.jpg/640px-Lincoln_Financial_Field_outside.jpg'
  'levis.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Levi%27s_Stadium_exterior.jpg/640px-Levi%27s_Stadium_exterior.jpg'
  'lumen.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/CenturyLink_Field_2011.jpg/640px-CenturyLink_Field_2011.jpg'
  'arrowhead.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Arrowhead_Stadium_2010.jpg/640px-Arrowhead_Stadium_2010.jpg'
  'gillette.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Gillette_Stadium_2014.jpg/640px-Gillette_Stadium_2014.jpg'
  'bmo.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/BMO_Field_2016.jpg/640px-BMO_Field_2016.jpg'
  'bc_place.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/BC_Place_stadium.jpg/640px-BC_Place_stadium.jpg'
  'azteca.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Estadio_Azteca_2015.jpg/640px-Estadio_Azteca_2015.jpg'
  'akron.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Estadio_Akron_2010.jpg/640px-Estadio_Akron_2010.jpg'
  'bbva.jpg' = 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Estadio_BBVA_Bancomer.jpg/640px-Estadio_BBVA_Bancomer.jpg'
}

foreach ($entry in $downloads.GetEnumerator()) {
  $dest = Join-Path $outDir $entry.Key
  try {
    Invoke-WebRequest -Uri $entry.Value -OutFile $dest -TimeoutSec 60
    Write-Host "OK $($entry.Key)"
  } catch {
    Write-Host "FAIL $($entry.Key): $_"
  }
}
