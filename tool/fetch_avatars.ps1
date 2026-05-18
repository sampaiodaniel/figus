# Downloads 25 DiceBear "avataaars" SVGs into assets/avatars/.
# 5 free (covering white M/F, black M/F, asian) + 20 pro (varied + festive).
#
# Run from project root:
#   powershell -ExecutionPolicy Bypass -File tool/fetch_avatars.ps1

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Each entry: hashtable of DiceBear avataaars params. The 'id' becomes the
# output filename. Keys other than 'id' are appended verbatim to the query.
#
# DiceBear v9 skinColor palette (hex without #):
#   tanned=fd9841  yellow=f8d25c  pale=ffdbb4  light=edb98a
#   brown=d08b5b   darkBrown=ae5d29  black=614335
$avatars = @(
  # ───────── FREE (5) ─────────
  @{ id='avatar_01'; seed='figus01'
     skinColor='edb98a'; top='longButNotTooLong'; hairColor='d6b370'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtScoopNeck'; clothesColor='ff488e'
     backgroundColor='c0aede' },

  @{ id='avatar_02'; seed='figus02'
     skinColor='edb98a'; top='shortFlat'; hairColor='4a312c'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtCrewNeck'; clothesColor='5199e4'
     backgroundColor='b6e3f4' },

  @{ id='avatar_03'; seed='figus03'
     skinColor='614335'; top='shortRound'; hairColor='2c1b18'
     facialHair='beardMedium'; facialHairProbability='100'; facialHairColor='2c1b18'
     accessoriesProbability='0'
     clothing='shirtCrewNeck'; clothesColor='262e33'
     backgroundColor='d1d4f9' },

  @{ id='avatar_04'; seed='figus04'
     skinColor='d08b5b'; top='fro'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtScoopNeck'; clothesColor='ffffb1'
     backgroundColor='ffd5dc' },

  @{ id='avatar_05'; seed='figus05'
     skinColor='f8d25c'; top='straight02'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='collarAndSweater'; clothesColor='ff488e'
     backgroundColor='c0aede' },

  # ───────── PRO · classics (7) ─────────
  @{ id='avatar_06'; seed='figus06'
     skinColor='fd9841'; top='longButNotTooLong'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtScoopNeck'; clothesColor='ffffff'
     backgroundColor='ffdfbf' },

  @{ id='avatar_07'; seed='figus07'
     skinColor='edb98a'; top='shortWaved'; hairColor='e8e1e1'
     facialHair='beardMajestic'; facialHairProbability='100'; facialHairColor='e8e1e1'
     accessoriesProbability='0'
     clothing='blazerAndShirt'
     backgroundColor='b6e3f4' },

  @{ id='avatar_08'; seed='figus08'
     skinColor='ffdbb4'; top='curly'; hairColor='c93305'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtVNeck'; clothesColor='a7ffc4'
     backgroundColor='ffffb1' },

  @{ id='avatar_09'; seed='figus09'
     skinColor='ae5d29'; top='shortFlat'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='hoodie'; clothesColor='ff488e'
     backgroundColor='d1d4f9' },

  @{ id='avatar_10'; seed='figus10'
     skinColor='f8d25c'; top='straight01'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtScoopNeck'; clothesColor='ff488e'
     backgroundColor='ffd5dc' },

  @{ id='avatar_11'; seed='figus11'
     skinColor='d08b5b'; top='dreads01'; hairColor='2c1b18'
     facialHair='beardLight'; facialHairProbability='100'; facialHairColor='2c1b18'
     accessoriesProbability='0'
     clothing='graphicShirt'; clothesColor='ff5c5c'
     backgroundColor='c0aede' },

  @{ id='avatar_12'; seed='figus12'
     skinColor='edb98a'; top='shortRound'; hairColor='2c1b18'
     facialHairProbability='0'
     accessories='prescription02'; accessoriesProbability='100'
     clothing='blazerAndSweater'; clothesColor='262e33'
     backgroundColor='ffdfbf' },

  # ───────── PRO · accessories (4) ─────────
  @{ id='avatar_13'; seed='figus13'
     skinColor='edb98a'; top='bob'; hairColor='2c1b18'
     facialHairProbability='0'
     accessories='prescription01'; accessoriesProbability='100'
     clothing='shirtCrewNeck'; clothesColor='929598'
     backgroundColor='b6e3f4' },

  @{ id='avatar_14'; seed='figus14'
     skinColor='fd9841'; top='shortCurly'; hairColor='2c1b18'
     facialHair='beardLight'; facialHairProbability='100'; facialHairColor='2c1b18'
     accessories='sunglasses'; accessoriesProbability='100'
     clothing='graphicShirt'; clothesColor='262e33'
     backgroundColor='c0aede' },

  @{ id='avatar_15'; seed='figus15'
     skinColor='edb98a'; top='theCaesarAndSidePart'; hairColor='4a312c'
     facialHair='beardLight'; facialHairProbability='100'; facialHairColor='4a312c'
     accessories='round'; accessoriesProbability='100'
     clothing='collarAndSweater'; clothesColor='3c4f5c'
     backgroundColor='ffdfbf' },

  @{ id='avatar_16'; seed='figus16'
     skinColor='ffdbb4'; top='longButNotTooLong'; hairColor='f59797'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='hoodie'; clothesColor='ff488e'
     backgroundColor='ffd5dc' },

  # ───────── PRO · festive (6) ─────────
  @{ id='avatar_17'; seed='figus17'
     skinColor='fd9841'; top='shortFlat'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtCrewNeck'; clothesColor='ffffb1'
     backgroundColor='25557c' },

  @{ id='avatar_18'; seed='figus18'
     skinColor='d08b5b'; top='bigHair'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtScoopNeck'; clothesColor='a7ffc4'
     backgroundColor='ffffb1' },

  @{ id='avatar_19'; seed='figus19'
     skinColor='ffdbb4'; top='hat'; hairColor='2c1b18'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='blazerAndShirt'
     backgroundColor='ff5c5c' },

  @{ id='avatar_20'; seed='figus20'
     skinColor='edb98a'; top='winterHat04'
     facialHair='beardMajestic'; facialHairProbability='100'; facialHairColor='e8e1e1'
     accessoriesProbability='0'
     clothing='shirtCrewNeck'; clothesColor='ff5c5c'
     backgroundColor='a7ffc4' },

  @{ id='avatar_21'; seed='figus21'
     skinColor='fd9841'; top='hat'; hairColor='4a312c'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='graphicShirt'; clothesColor='ff488e'
     backgroundColor='ffffb1' },

  @{ id='avatar_22'; seed='figus22'
     skinColor='edb98a'; top='bigHair'; hairColor='f59797'
     facialHairProbability='0'
     accessories='sunglasses'; accessoriesProbability='100'
     clothing='graphicShirt'; clothesColor='ff488e'
     backgroundColor='c0aede' },

  # ───────── PRO · extra (3) ─────────
  @{ id='avatar_23'; seed='figus23'
     skinColor='edb98a'; top='shortFlat'; hairColor='e8e1e1'
     facialHair='beardMedium'; facialHairProbability='100'; facialHairColor='e8e1e1'
     accessories='prescription02'; accessoriesProbability='100'
     clothing='blazerAndShirt'; clothesColor='262e33'
     backgroundColor='b6e3f4' },

  @{ id='avatar_24'; seed='figus24'
     skinColor='fd9841'; top='hijab'
     facialHairProbability='0'; accessoriesProbability='0'
     clothing='shirtCrewNeck'; clothesColor='ff488e'
     backgroundColor='c0aede' },

  @{ id='avatar_25'; seed='figus25'
     skinColor='d08b5b'; top='turban'
     facialHair='beardMedium'; facialHairProbability='100'; facialHairColor='2c1b18'
     accessoriesProbability='0'
     clothing='blazerAndShirt'
     backgroundColor='ffdfbf' }
)

$outDir = Join-Path $PSScriptRoot '..\assets\avatars'
$outDir = (Resolve-Path $outDir).Path
Write-Host "Saving to: $outDir"

$count = 0
foreach ($a in $avatars) {
  $id = $a['id']
  $parts = New-Object System.Collections.ArrayList
  foreach ($key in $a.Keys) {
    if ($key -eq 'id') { continue }
    [void]$parts.Add("$key=$($a[$key])")
  }
  $query = $parts -join '&'
  $url = "https://api.dicebear.com/9.x/avataaars/svg?$query"
  $out = Join-Path $outDir "$id.svg"

  Write-Host "  [$($count + 1)/25] $id ... " -NoNewline
  try {
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    Write-Host "OK ($([math]::Round((Get-Item $out).Length / 1024, 1)) KB)"
  } catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    throw
  }
  $count++
}

Write-Host ""
Write-Host "Done. $count avatars written to $outDir" -ForegroundColor Green
