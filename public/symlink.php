

 <?php
//$target =$_SERVER['DOCUMENT_ROOT'].'/storage/app/public';
//$link = $_SERVER['DOCUMENT_ROOT'].'/public/storage';
//symlink($target, $link);
//echo "Done";


$target =$_SERVER['DOCUMENT_ROOT'].'/jago/storage/app/public';
$link = $_SERVER['DOCUMENT_ROOT'].'/jago/public/storage';
symlink($target, $link);
echo "Done";
?> 