servers="ZOO-Project 52°North"
dirs="testing testing52"
ddir="testing"

rm /var/www/$ddir/WPS_BenchmarkGCA.html
cat /var/www/$ddir/templates/template_gchead.tmpl > /var/www/$ddir/WPS_BenchmarkGCA.html
for i in $dirs; do
    (echo "<section>" ; cat /var/www/$i/tmp/WPS_BenchmarkGC.html | sed "s:../tmp/:/$i/tmp/:g";echo "</section>") >> /var/www/$ddir/WPS_BenchmarkGCA.html
done

cp ../gnuplot_scripts/run42.tsv ../tmp/run43.tsv 
for i in 0 1 2 ; do 
    cat ../tmp/run$(expr 4 + $i)3.tsv | sed "s:\[file$i\]:/var/www/testing/tmp/statGetCapabilities$i.plot:g" > ../tmp/run$(expr 5 + $i)3.tsv 
done

for i in 0 1 2 ; do 
    cat ../tmp/run$(expr 7 + $i)3.tsv | sed "s:\[file$(expr $i + 3)\]:/var/www/testing52/tmp/statGetCapabilities$i.plot:g" > ../tmp/run$(expr 8 + $i)3.tsv
done 

for i in 0 1 2 ; do
    cat ../tmp/run$(expr 10 + $i)3.tsv | sed "s:\[leg$i\]:ZOO-Project $i:g" > ../tmp/run$(expr 11 + $i)3.tsv 
done

for i in 0 1 2 ; do
    cat ../tmp/run$(expr 13 + $i)3.tsv | sed "s:\[leg$(expr $i + 3)\]:52° North $i:g" > ../tmp/run$(expr 14 + $i)3.tsv 
done

cat ../tmp/run163.tsv | sed "s:\[title\]:GetCapabilities:g;s:\[image\]:/var/www/$ddir/tmp/globalGC.jpg:g" > ../tmp/run173.tsv 
gnuplot ../tmp/run173.tsv 

(echo "<section><section> <h2>GetCapabilties Results</h2> <img style='width: 1250px;' src='/$ddir/tmp/globalGC.jpg'/> </section>" ; cat /var/www/$ddir/templates/template_gcfooter.tmpl;echo  "</section>") >> /var/www/$ddir/WPS_BenchmarkGCA.html


rm /var/www/$ddir/WPS_BenchmarkDPA.html
cat /var/www/$ddir/templates/template_dphead.tmpl > /var/www/$ddir/WPS_BenchmarkDPA.html
for i in $dirs; do
    (echo "<section>" ; cat /var/www/$i/tmp/WPS_BenchmarkDP.html | sed "s:../tmp/:/$i/tmp/:g";echo "</section>") >> /var/www/$ddir/WPS_BenchmarkDPA.html
done

cp ../gnuplot_scripts/run41.tsv ../tmp/run43.tsv 
for i in 0 1 2 ; do 
    cat ../tmp/run$(expr 4 + $i)3.tsv | sed "s:\[file$i\]:/var/www/testing/tmp/statDescribeProcess$(expr $i + 7).plot:g" > ../tmp/run$(expr 5 + $i)3.tsv 
done

for i in 0 1 ; do 
    cat ../tmp/run$(expr 7 + $i)3.tsv | sed "s:\[file$(expr $i + 3)\]:/var/www/testing52/tmp/statDescribeProcess$(expr $i + 8).plot:g" > ../tmp/run$(expr 8 + $i)3.tsv
done 

for i in 0 1 2; do
    cat ../tmp/run$(expr 9 + $i)3.tsv | sed "s:\[leg$i\]:ZOO-Project $(expr $i + 7) :g" > ../tmp/run$(expr 10 + $i)3.tsv 
done

for i in 0 1 ; do
    cat ../tmp/run$(expr 12 + $i)3.tsv | sed "s:\[leg$(expr $i + 3)\]:52° North $(expr $i + 8):g" > ../tmp/run$(expr 13 + $i)3.tsv 
done

cat ../tmp/run143.tsv | sed "s:\[title\]:DescribeProcess:g;s:\[image\]:/var/www/$ddir/tmp/globalDP.jpg:g" > ../tmp/run173.tsv 
gnuplot ../tmp/run173.tsv 

(echo "<section><section> <h2>DescribeProcess Results</h2> <img style='width: 1250px;' src='/$ddir/tmp/globalDP.jpg'/> </section>"; cat /var/www/$ddir/templates/template_dpfooter.tmpl;echo  "</section>") >> /var/www/$ddir/WPS_BenchmarkDPA.html


rm /var/www/$ddir/WPS_BenchmarkESA.html
rm /var/www/$ddir/WPS_BenchmarkEAA.html
cat /var/www/$ddir/templates/template_eshead.tmpl > /var/www/$ddir/WPS_BenchmarkESA.html
cat /var/www/$ddir/templates/template_eahead.tmpl > /var/www/$ddir/WPS_BenchmarkEAA.html
for i in $dirs; do
    (echo "<section>" ; (cat /var/www/$i/tmp/WPS_BenchmarkES.html | sed "s:tmp/:/$i/tmp/:g" || echo "<h2>Test did not run</h2>" ) ;echo "</section>") >> /var/www/$ddir/WPS_BenchmarkESA.html
    (echo "<section>" ; (cat /var/www/$i/tmp/WPS_BenchmarkEA.html | sed "s:tmp/:/$i/tmp/:g" || echo "<h2>Test did not run</h2>" );echo "</section>") >> /var/www/$ddir/WPS_BenchmarkEAA.html
done



cat /var/www/$ddir/WPS_BenchmarkGCA.html > /var/www/$ddir/WPS_BenchmarkA.html
cat /var/www/$ddir/WPS_BenchmarkDPA.html >> /var/www/$ddir/WPS_BenchmarkA.html
(echo "<section><section> <h2>Execute Synch Results</h2> </section>"; cat /var/www/$ddir/templates/template_esfooter.tmpl;echo  "</section>") >> /var/www/$ddir/WPS_BenchmarkESA.html
cat /var/www/$ddir/WPS_BenchmarkESA.html >> /var/www/$ddir/WPS_BenchmarkA.html
(echo "<section><section> <h2>Execute Asynch Results</h2> </section>"; cat /var/www/$ddir/templates/template_eafooter.tmpl;echo  "</section>") >> /var/www/$ddir/WPS_BenchmarkEAA.html
cat /var/www/$ddir/WPS_BenchmarkEAA.html >> /var/www/$ddir/WPS_BenchmarkA.html

cat /var/www/$ddir/templates/template_header.tmpl >  /var/www/$ddir/WPS_BenchmarkAF.html
cat /var/www/$ddir/WPS_BenchmarkA.html >>  /var/www/$ddir/WPS_BenchmarkAF.html
cat /var/www/$ddir/templates/template_footer.tmpl >> /var/www/$ddir/WPS_BenchmarkAF.html

cp /var/www/$ddir/WPS_BenchmarkAF.html /var/www/$ddir/../OSGeoLive-presentation-master/

