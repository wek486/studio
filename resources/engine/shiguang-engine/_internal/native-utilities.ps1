param(
    [ValidateSet('capabilities','ocr','pdf')][string]$Mode='capabilities',
    [string]$InputPath,
    [string]$OutputPath,
    [string]$Language,
    [int]$Dpi=144,
    [int]$FirstPage=1,
    [int]$LastPage=0
)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $script:asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } | Select-Object -First 1
    $script:asAction = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
    } | Select-Object -First 1
    function Await($Operation,[Type]$ResultType) {
        $task=$script:asTask.MakeGenericMethod($ResultType).Invoke($null,@($Operation))
        $task.GetAwaiter().GetResult()
    }
    function AwaitAction($Operation) {
        $task=$script:asAction.Invoke($null,@($Operation))
        $null=$task.GetAwaiter().GetResult()
    }
    [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.SoftwareBitmap,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null
    [Windows.Media.Ocr.OcrEngine,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null
    [Windows.Globalization.Language,Windows.Foundation,ContentType=WindowsRuntime] | Out-Null
    $languages=@([Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages | ForEach-Object LanguageTag)
    $pdfAvailable=$true
    try { [Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime] | Out-Null } catch { $pdfAvailable=$false }
    if($Mode -eq 'capabilities') {
        $result=@{ocr=($languages.Count -gt 0);pdfImport=$pdfAvailable;languages=$languages;maxOcrDimension=[Windows.Media.Ocr.OcrEngine]::MaxImageDimension}
        if($languages.Count -eq 0){$result.ocrReason='Windows OCR language pack is not installed.'}
    } elseif($Mode -eq 'ocr') {
        if($languages.Count -eq 0){throw 'Windows OCR language pack is not installed.'}
        if($Language) {
            $lang=New-Object Windows.Globalization.Language($Language)
            if(-not [Windows.Media.Ocr.OcrEngine]::IsLanguageSupported($lang)){throw 'The selected OCR language is not installed.'}
            $engine=[Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
        } else {
            $engine=[Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
            if(-not $engine){$engine=[Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage((New-Object Windows.Globalization.Language($languages[0])))}
        }
        $file=Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($InputPath)) ([Windows.Storage.StorageFile])
        $stream=Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        try {
            $decoder=Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
            $bitmap=Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
            $converted=[Windows.Graphics.Imaging.SoftwareBitmap]::Convert($bitmap,[Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8,[Windows.Graphics.Imaging.BitmapAlphaMode]::Premultiplied)
            try {
                $recognized=Await ($engine.RecognizeAsync($converted)) ([Windows.Media.Ocr.OcrResult])
                $lines=@($recognized.Lines | ForEach-Object {
                    $line=$_
                    $words=@($line.Words | ForEach-Object { @{text=$_.Text;x=$_.BoundingRect.X;y=$_.BoundingRect.Y;w=$_.BoundingRect.Width;h=$_.BoundingRect.Height} })
                    @{text=$line.Text;words=$words}
                })
                $result=@{text=($lines.text -join "`n");lines=$lines;languages=$languages;language=$engine.RecognizerLanguage.LanguageTag}
            } finally {$converted.Dispose();$bitmap.Dispose()}
        } finally {$stream.Dispose()}
    } else {
        if(-not $pdfAvailable){throw 'Windows PDF rendering is unavailable.'}
        if($Dpi -lt 36 -or $Dpi -gt 300){throw 'DPI must be 36 to 300.'}
        $file=Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($InputPath)) ([Windows.Storage.StorageFile])
        $document=Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
        $count=[int]$document.PageCount
        if($LastPage -eq 0){$LastPage=$count}
        if($FirstPage -lt 1 -or $FirstPage -gt $count -or $LastPage -lt $FirstPage -or $LastPage -gt $count){throw 'The selected PDF page range is invalid.'}
        if($LastPage-$FirstPage+1 -gt 100){throw 'At most 100 PDF pages can be exported at a time.'}
        $files=@()
        $totalPixels=0.0
        for($index=$FirstPage-1;$index -lt $LastPage;$index++) {
            $page=$document.GetPage([uint32]$index)
            try {
                $width=[uint32][Math]::Max(1,[Math]::Round($page.Size.Width*$Dpi/96))
                $height=[uint32][Math]::Max(1,[Math]::Round($page.Size.Height*$Dpi/96))
                $pixels=[double]$width*$height
                $totalPixels+=$pixels
                if($pixels -gt 32000000 -or $totalPixels -gt 256000000){throw 'Rendered PDF exceeds the image size limit. Lower DPI or select fewer pages.'}
                $target=Join-Path $OutputPath ('page-{0:d4}.png' -f ($index+1))
                if([IO.File]::Exists($target)){throw 'Output files already exist. Select another folder.'}
                $options=New-Object Windows.Data.Pdf.PdfPageRenderOptions
                $options.DestinationWidth=$width;$options.DestinationHeight=$height
                $memory=New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
                try {
                    AwaitAction ($page.RenderToStreamAsync($memory,$options))
                    $memory.Seek(0)
                    $net=[System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($memory)
                    $destination=[IO.File]::Create($target)
                    try {$net.CopyTo($destination)} finally {$destination.Dispose();$net.Dispose()}
                } finally {$memory.Dispose()}
                $files+=$target
            } finally {$page.Dispose()}
        }
        $result=@{saved=$true;count=$files.Count;pageCount=$count;files=$files;dpi=$Dpi}
    }
    @{ok=$true;result=$result}|ConvertTo-Json -Depth 10 -Compress
} catch {
    @{ok=$false;error=$_.Exception.Message}|ConvertTo-Json -Depth 4 -Compress
    exit 1
}
