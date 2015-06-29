#!/bin/bash

Usage=$(cat <<EOF
Please use the following syntaxe:

  ./run.sh <WPSInstance> <ServiceNames> <RequestTypes> <Requests> <Concurents>

where <WPSInstance> should be the url to a WPS Server and <ServiceName> should 
be the service name you want to run tests with, <RequestTypes> the types of 
requests you want to test, <Requests> is the number of requests to run during
the performance tests and <Concurents> is the number of concurrent requests to 
send.

For instance to test the Buffer service on a localhost WPS server, using the
GetCapabilties tests, run performance testing using 5000 requests with 100 
concurents use the following command:

  ./run.sh http://localhost/cgi-bin/zoo_loader.cgi Buffer GetCapabilities 5000 100 WFSURL

EOF
)

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "$Usage"
    exit
fi

WPSInstance=$1
ServiceName=$2
NBRequests=$4
NBConcurrents=$5
WFSURL=${GEOSERVER}

iter=0

function mycount {
    i=0
    for v in $1; do 
	i=$(expr $i + 1)
    done
    echo $i
}

function plotStat {
    cp ../gnuplot_scripts/run.tsv ../tmp/run$1.tsv
    sed "s:\[title\]:$4:g;s:\[image\]:$2:g;s:\[file\]:$3:g" -i ../tmp/run$1.tsv
    gnuplot ../tmp/run$1.tsv
    cp ../gnuplot_scripts/run1.tsv ../tmp/run1$1.tsv
    sed "s:\[title\]:$4:g;s:\[image\]:$(echo $2 | sed "s:.jpg:_1.jpg:g"):g;s:\[file\]:$3:g" -i ../tmp/run1$1.tsv
    gnuplot ../tmp/run1$1.tsv
}

function kvpRequest {
    if [ "${3}" != "owsExceptionReport" ]; then 
    	echo " <h3><a href='$1' target='_blank'>${3} KVP request</a> </h3>"
    else
    	echo " <h3><a href='$1' target='_blank'>Wrong ${4}</a> </h3>"
    fi
    echo "<ul>"
    RESP=$(curl -v -o "$2" "$1" 2> ../tmp/temp.log; grep "< HTTP" ../tmp/temp.log | cut -d' ' -f3)
    if [ "${3}" == "owsExceptionReport" ]; then
	if [ "$RESP" ==	"200" ]; then
	    echo " <li class='inv'> Invalid response code ($RESP) </li>"
	else
	    echo " <li class='v'> Valid response code ($RESP) </li>"
	fi
	xmllint --noout --schema http://schemas.opengis.net/ows/1.1.0/${3}.xsd "$2" 2> ../tmp/res${iter}.txt
	isValid="$(cat ../tmp/res${iter}.txt | grep -v error | grep validates)"
	if [ "$isValid" != "" ] ; then
		echo "<li class='v'>"
		f="$( cat ../tmp/res${iter}.txt | awk {'print $1'})"
		echo "<a href='$f' target='_blank'>${3} response</a> validates against <a href='http://schemas.opengis.net/ows/1.1.0/${3}.xsd'  target='_blank'>${3}.xsd</a>"
	else
		echo "<li class='inv'>"
		cat ../tmp/res${iter}.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:<br />:g' > ../tmp/res${iter}11.html
		echo "<a href='$2' target='_blank'>${3} response</a> did not validate see <a href='../tmp/res${iter}11.html'>ref.</a>"
	fi
	echo " </li>"
	echo " <li class='r'> "
	xsltproc ../xsl/extractExceptionInfo.xsl "$2"
	echo " </li>"
	imgTop="215px";
    else
	if [ "$RESP" ==	"200" ]; then
	    echo " <li class='v'> Valid response code ($RESP) </li>"
	else
	    echo " <li class='inv'> Invalid response code ($RESP) </li>"
	fi
	xmllint --noout --schema http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd "$2" 2> ../tmp/res${iter}.txt
	isValid="$(cat ../tmp/res${iter}.txt | grep validates)"
	if [ "$isValid" != "" ] ; then
		echo "<li class='v'>"
		f="$( cat ../tmp/res${iter}.txt | awk {'print $1'})"
		echo "<a href='$f' target='_blank'>${3} response</a> validates against  <a href='http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd' target='_blank'>${3}_response.xsd</a>"
	else
		cat ../tmp/res${iter}.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:<br />:g' > ../tmp/res${iter}2.html
		echo "<li class='inv'> <a href='$2' target='_blank'>${3} response</a> did not validates see <a href='../tmp/res${iter}2.html' target='_blank'>ref</a>."
	fi
	echo " </li> "
	imgTop="180px";
    fi
    echo "</ul>"
    #echo " <h3> Sending $NBRequests ${3} requests starting on $(date) ...</h3>"
    rm ../tmp/stat${3}${iter}.plot ../tmp/stat${3}${iter}.txt ../tmp/stat${3}${iter}.jpg
    ab -v0 -g ../tmp/stat${3}${iter}.plot -e ../tmp/stat${3}${iter}.txt -n "$NBRequests" -c "$NBConcurrents" "$1" > log
    plotStat ${iter} ../tmp/stat${3}${iter}.jpg ../tmp/stat${3}${iter}.plot "${3} (${iter})"
    echo " <!-- <a href="../tmp/stat${3}${iter}.jpg"  target='_blank'>IMG</a> --><img class="stats" src='../tmp/stat${3}${iter}.jpg' style='float: right;position:absolute;top: $imgTop;' />"
    #echo " <table><tr><td>"
    echo "<pre class="stats"><code>"
    cat log | grep -A16 Server | grep -v "HTML transferred" # | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:</td></tr><tr>\n<td>:g;s/:/<\/td><td>/g'
    echo "</code></pre>"
    #echo " </td><td></td></tr></table>"
    iter=$(expr $iter + 1)
}

function postRequest {
    echo " <h2> ${3} POST request </h2>"
    echo " <ul>"
    xmllint --noout --schema http://schemas.opengis.net/wps/1.0.0/wps${3}_request.xsd "$4" 2> ../tmp/res${iter}.txt
    isValid="$(cat ../tmp/res${iter}.txt | grep -v error | grep validates)"
    if [ "$isValid" != "" ] ; then
	echo "<li class='v'>"
	f="$( cat ../tmp/res${iter}.txt | awk {'print $1'})"
	echo "<a href='$f' target='_blank'>${3} request</a> validates against <a href='http://schemas.opengis.net/wps/1.0.0/wps${3}_request.xsd' target='_blank'>wps${3}_request.xsd</a>"
    else
	echo "<li class='inv'>"
	cat ../tmp/res${iter}.txt |sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:<br />:g' > tmp ../tmp/res${iter}.html
	echo "<a href='$4' target='_blank'>${3} request</a> did not validate see <a href='../tmp/res${iter}.html'>ref.</a>"
    fi
    echo " </li>"
    curl -v -H "Content-type: text/xml" -d@"$4" -o "$2" "$1" 2> ../tmp/temp.log
    RESP=$(grep "< HTTP" ../tmp/temp.log | grep -v "100" | cut -d' ' -f3)
	if [ "$RESP" ==	"200" ]; then
	    echo " <li class='v'> Valid response code ($RESP) </li>"
	else
	    echo " <li class='inv'> Invalid response code ($RESP) </li>"
	fi
    xmllint --noout --schema http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd "$2" 2> ../tmp/res${iter}1.txt
    isValid="$(cat ../tmp/res${iter}1.txt | grep -v error | grep validates)"
    if [ "$isValid" != "" ] ; then
	echo "<li class='v'>"
	f="$( cat ../tmp/res${iter}1.txt | awk {'print $1'})"
	echo "<a href='$f' target='_blank'>${3} response</a> validates against <a href='http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd' target='_blank'>${3} response Schema</a>"
    else
	echo "<li class='inv'>"
	cat ../tmp/res${iter}1.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:<br />:g' > ../tmp/res${iter}1.html
	echo "<a href='$2' target='_blank'>${3} response</a> did not validate see <a href='../tmp/res${iter}1.html' target='_blank'>ref.</a>"
    fi
    echo " </li>"
    if [ -z "$5" ]; then
	echo ""
    else
	tmp=$(echo $2 | sed "s:.xml:2.xml:g")
	file="$(xsltproc ../xsl/extractStatusLocation.xsl $2)"
	curl -v -o "$tmp" "$file" 2> ../tmp/temp.log
	xmllint --noout --schema http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd "$tmp" 2> ../tmp/res${iter}2.txt 
	isValid="$(cat ../tmp/res${iter}2.txt | grep -v error | grep validates)"
	if [ "$isValid" != "" ] ; then
		echo "<li class='v'>"
		f="$( cat ../tmp/res${iter}.txt | awk {'print $1'})"
		echo "<a href='$tmp' target='_blank'>statusLocation</a> validates against <a href='http://schemas.opengis.net/wps/1.0.0/wps${3}_response.xsd' target='_blank'>wps${3}_response.xsd Schema</a> (final result is <a href='$file' target='_blank'>here</a>)."
	else
		echo "<li class='inv'>"
		cat ../tmp/res${iter}2.txt | sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:<br />:g' > ../tmp/res${iter}2.html
		echo "<a href='$file' target='_blank'>statusLocation</a> did not validate see <a href='../tmp/res${iter}2.html' target='_blank'>ref.</a>"
	fi
	echo "</li>"
    fi
    echo "</ul>"
    ab -g ../tmp/stat${3}${iter}.plot -e ../tmp/stat${3}${iter}.txt -T "text/xml" -p "$4" -n "$NBRequests" -c "$NBConcurrents" "$1" > log
    plotStat ${iter} ../tmp/stat${3}${iter}.jpg ../tmp/stat${3}${iter}.plot "${3} (${iter})"
    echo " <img src="../tmp/stat${3}${iter}.jpg"  class="stats" style='float: right;position:absolute;top:215px;'  />"
    #echo " <table><tr><td>"
    echo "<pre class="stats"><code>"
    cat log | grep -A16 Server | grep -v "HTML transferred" #| sed -e ':a' -e 'N' -e '$!ba' -e 's:\n:</td></tr><tr>\n<td>:g;s/:/<\/td><td>/g'
    echo "</code></pre>"
    # echo " </td><td></td></tr></table>"
    iter=$(expr $iter + 1)
}

function kvpRequestWrite {
    suffix=""
    cnt=0
    cnt0=0
    for i in $2; do
	if [ ! $1 -eq $cnt0 ]; then
	    if [ $cnt -gt 0 ]; then
		suffix="$suffix&$(echo $i | sed 's:\"::g')"
	    else
		suffix="$(echo $i | sed 's:\"::g')"
	    fi
	    cnt=$(expr $cnt + 1)
	fi
	cnt0=$(expr $cnt0 + 1)
    done
    echo $suffix
}

function kvpWrongRequestWrite {
    suffix=""
    cnt=0
    cnt0=0
    for i in $2; do
	if [ ! $1 -eq $cnt0 ]; then
	    if [ $cnt0 -gt 0 ]; then
		suffix="$suffix&$(echo $i | sed 's:\"::g')"
	    else
		suffix="$(echo $i | sed 's:\"::g')"
	    fi
	    cnt=$(expr $cnt + 1)
	else
	    cnt1=0
	    for j in $3; do 
		if [ $cnt1 -eq $1 ]; then
		    if [ $cnt0 -gt 0 ]; then
		        suffix="$suffix&$(echo $j | sed 's:\"::g')"
		    else
		        suffix="$(echo $j | sed 's:\"::g')"
		    fi
		fi
		cnt1=$(expr $cnt1 + 1)
	    done
	fi
	cnt0=$(expr $cnt0 + 1)
    done
    echo $suffix
}



for i in $3; do
#echo $i
	if [ "$i" == "GetCapabilities" ]; then
#
# Tests for GetCapabilities using KVP (including wrong requests) and POST requests
#
echo "<section>"
kvpRequest "${WPSInstance}?REQUEST=GetCapabilities&SERVICE=WPS" "../tmp/outputGC1.xml" "GetCapabilities"
echo "</section>"

params='"request=GetCapabilities" "service=WPS"'

suffix=$(kvpRequestWrite -1 "$params")
echo "<section>"
kvpRequest "${WPSInstance}?$suffix" "../tmp/outputGC2.xml" "GetCapabilities"
echo "</section>"

curl -o ../tmp/10_wpsGetCapabilities_request.xml http://schemas.opengis.net/wps/1.0.0/examples/10_wpsGetCapabilities_request.xml
cat ../tmp/10_wpsGetCapabilities_request.xml | sed "s:en-CA:en-US:g" > ../tmp/10_wpsGetCapabilities_request1.xml
echo "<section>"
postRequest "${WPSInstance}" "../tmp/outputGCp.xml" "GetCapabilities" "../tmp/10_wpsGetCapabilities_request1.xml"
echo "</section>"

for j in 0 1; do 
    suffix=$(kvpRequestWrite $j "$params")
    echo "<section>"
    kvpRequest "${WPSInstance}?$suffix" "../tmp/outputGC$(expr $j + 3).xml" "owsExceptionReport" "GetCapabilities"
    echo "</section>"
done

paramsw='"request=GetCapabilitie" "service=WXS"'
for j in 0 1; do 
    suffix=$(kvpWrongRequestWrite $j "$params" "$paramsw")
    echo "<section>"
    kvpRequest "${WPSInstance}?$suffix" "../tmp/outputGC$(expr $j + 5).xml" "owsExceptionReport" "GetCapabilities"
    echo "</section>"
done

#echo "Check if differences between upper case and lower case parameter names"
#diff -ru ../tmp/outputGC1.xml ../tmp/outputGC2.xml 

#echo ""

echo ""
	fi
	if [ "$i" == "DescribeProcess" ]; then
iter=7
#
# Tests for DescribeProcess using KVP and POST requests
#
echo "<section>"
kvpRequest "${WPSInstance}?request=DescribeProcess&service=WPS&version=1.0.0&Identifier=ALL" "../tmp/outputDPall.xml" "DescribeProcess"
echo "</section>"


Services=${ServiceName}
ii=0
for kk in $Services; do
ServiceName=$kk
params='"request=DescribeProcess" "service=WPS" "version=1.0.0" "Identifier='${ServiceName}'"'
suffix=$(kvpRequestWrite -1 "$params")
echo "<section>"
kvpRequest "${WPSInstance}?$suffix" "../tmp/outputDPb${ii}1.xml" "DescribeProcess"
xsltproc ../xsl/extractInputs.xsl ../tmp/outputDPb${ii}1.xml > ../tmp/inputName${ii}.txt
echo "</section>"

cat ../requests/dp.xml | sed "s:ServiceName:${ServiceName}:g" > ../tmp/dp${ii}1.xml
echo "<section>"
postRequest "${WPSInstance}" "../tmp/outputDPp${ii}.xml" "DescribeProcess" "../tmp/dp${ii}1.xml"
echo "</section>"
ii=$(expr $ii + 1)
done

for j in 0 1 2 3; do 
    suffix=$(kvpRequestWrite $j "$params")
    echo "<section>"
    kvpRequest "${WPSInstance}?$suffix" "../tmp/outputDPb${ii}$(expr $j + 2).xml" "owsExceptionReport" "DescribeProcess"
    echo "</section>"
done

paramsw='"request=DescribeProces" "service=WXS" "version=1.2.0" "Identifier=Undefined"'
for j in 0 1 2 3; do 
    suffix=$(kvpWrongRequestWrite $j "$params" "$paramsw")
    echo "<section>"
    kvpRequest "${WPSInstance}?$suffix" "../tmp/outputDPb${ii}$(expr $j + 11).xml" "owsExceptionReport" "DescribeProcess"
    echo "</section>"
done

#echo "<section>"
#kvpRequest "${WPSInstance}?request=DescribeProcess&service=WPS&Identifier=${ServiceName}" "../tmp/outputDPb10.xml" "DescribeProcess"
#echo "</section>"
#echo ""

echo "" 
	fi
	if [ "$i" == "ExecuteSync" ]; then
iter=18

Services=${ServiceName}
ii=0
for kk in $Services; do
ServiceName=$kk
#
# Tests for Execute using POST requests
#
for i in ijson_o igml_o igmlb64_o ir_o ir_or irb_o irb_or irbr_o irbr_or; 
do
    cat ../requests/${i}.xml | sed "s:ServiceName:${ServiceName}:g;s|GEOSERVER|${WFSURL}|g;s|CPTESTING|${CPTESTING}|g" > ../tmp/${i}${ii}1.xml
    li=2
    nb=0
    for v in $(cat ../tmp/inputName${ii}.txt); do 
	nb=$(expr $nb + 1)
    done
    file=../tmp/${i}${ii}1.xml
    #echo $nb
    if [ $nb -gt 1 ]; then
    cat ../requests/$(echo $i | sed "s:_:2_:g").xml | sed "s:ServiceName:${ServiceName}:g;s|GEOSERVER|${WFSURL}|g;s|CPTESTING|${CPTESTING}|g" > ../tmp/${i}${ii}1.xml
    nbi=1
    for j in $(cat ../tmp/inputName${ii}.txt); do
    	cat $file | sed "s:InputName${nbi}:${j}:g" > ../tmp/${i}${ii}${li}.xml
	file=../tmp/${i}${ii}${li}.xml
	li=$(expr $li + 1)
	nbi=$(expr $nbi + 1)
    done
    else
    for j in $(cat ../tmp/inputName${ii}.txt); do
    	cat $file | sed "s:InputName:${j}:g" > ../tmp/${i}${ii}${li}.xml
	file=../tmp/${i}${ii}${li}.xml
	li=$(expr $li + 1)
    done
    fi
    #echo $file
    if [ "$li" -ge 2 ]; then
	li=$(expr $li - 1)
    fi
    echo "<section>"
    if [ -z "$(echo $i | grep async)" ]; then
	postRequest "${WPSInstance}" "../tmp/outputE${i}${ii}.xml" "Execute" "$file"
    else
	postRequest "${WPSInstance}" "../tmp/outputE${i}${ii}.xml" "Execute" "$file" "async"
    fi
    echo "</section>"
    echo ""
done
ii=$(expr $ii + 1)
done

echo ""
	fi
	if [ "$i" == "ExecuteAsync" ]; then

iter=35
ii=0
Services=${ServiceName}
for kk in $Services; do
ServiceName=$kk
#
# Tests for Execute using POST requests
#
for i in ir_o_async ir_or_async irb_o_async irb_or_async; 
do
    cat ../requests/${i}.xml | sed "s:ServiceName:${ServiceName}:g;s|GEOSERVER|${WFSURL}|g;s|CPTESTING|${CPTESTING}|g" > ../tmp/${i}${ii}1.xml
    li=2
    nb=0
    for v in $(cat ../tmp/inputName${ii}.txt); do 
	nb=$(expr $nb + 1)
    done
    file=../tmp/${i}${ii}1.xml
    #echo $nb
    if [ $nb -gt 1 ]; then
    cat ../requests/$(echo $i | sed "s:_:2_:").xml | sed "s:ServiceName:${ServiceName}:g;s|GEOSERVER|${WFSURL}|g;s|CPTESTING|${CPTESTING}|g" > ../tmp/${i}${ii}1.xml
    nbi=1
    for j in $(cat ../tmp/inputName${ii}.txt); do
    	cat $file | sed "s:InputName${nbi}:${j}:g" > ../tmp/${i}${ii}${li}.xml
	file=../tmp/${i}${ii}${li}.xml
	li=$(expr $li + 1)
	nbi=$(expr $nbi + 1)
    done
    else
    for j in $(cat ../tmp/inputName${ii}.txt); do
    	cat $file | sed "s:InputName:${j}:g" > ../tmp/${i}${ii}${li}.xml
	file=../tmp/${i}${ii}${li}.xml
	li=$(expr $li + 1)
    done
    fi
    if [ "$li" -ge 2 ]; then
	li=$(expr $li - 1)
    fi
    echo "<section>"
    if [ -z "$(echo $i | grep async)" ]; then
	postRequest "${WPSInstance}" "../tmp/outputE${ii}${i}.xml" "Execute" "$file"
    else
	postRequest "${WPSInstance}" "../tmp/outputE${ii}${i}.xml" "Execute" "$file" "async"
    fi
    echo "</section>"
    echo ""
done
ii=$(expr $ii + 1)
done

echo ""
	fi
done
