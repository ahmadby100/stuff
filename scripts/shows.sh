#!/usr/bin/bash

    # Script written by Ahmad Usayd (2020)
    # jq is required to parse JSON 
    # curl is used to call the API
    # The Movie Database API is used, Please add in your API Key from their website below:
    apikey="a359adb0d308edb4b532a6dedc37a2e5"


    #Setting colors
    black=$(tput setaf 0;)
    red=$(tput setaf 1;)
    green=$(tput setaf 2;)
    yellow=$(tput setaf 3;)
    blue=$(tput setaf 4;)
    purple=$(tput setaf 5;)
    cyan=$(tput setaf 6;)
    white=$(tput setaf 7;)

    endline=$(tput sgr 0;)

    echo "${green}Enter the name of the Show: ${red}[Make sure the name is exactly as the path or else it will break]${cyan}"
    read -r shows
    echo "${endline}"

    function query {
        curl -s --request GET \
            --url "https://api.themoviedb.org/3/search/tv?query=$titleurl&language=en-US&api_key=$apikey" \
            --header 'content-type: application/json'
    }

    function idquery 
    {
        curl -s --request GET \
        --url "https://api.themoviedb.org/3/tv/$id?language=en-US&api_key=$apikey&append_to_response=videos" \
        --header 'content-type: application/json'
    }

    #Remove brackets for clean search [title]
    cleanpath=$(echo $shows | sed -e 's/([^()]*)//g')

    #Convert to URL by changing spaces into %20
	titleurl=${cleanpath// /%20}

    #executing search API call
    data=$(query)
    

    #Filtering Name
	name=$(echo "$data" | jq '.results[0] .name' | tr -d "\"")

    #Filtering release date
    rdate=$(echo "$data" | jq '.results[0] .first_air_date' | tr -d "\"")
    year=$(echo $rdate | cut -c1-4)
    echo " "

    if [[ $name == "null" ]]
    then
        tput bold; echo "${red}No matches found${endline}"
        exit 1;
    fi
    tput bold; echo "${green}Result found: $name ${endline}(${cyan}$year${endline})"
    echo "Correct Result? (Y/n) ${cyan}"
        read -n 1 -r 
    #echo " "
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            exit 1;
        fi

    tput bold; echo "${purple}$name${endline}"
    echo "$name" >> /var/www/test/test/newlyadded.txt
    
    #Filtering user rating
    rating=$(echo "$data" | jq '.results[0] .vote_average' | tr -d "\"")
    
        if [ -z "$rating" ]
        then
            echo "${red}Error finding rating${endline}"
            echo "  Error finding rating" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Rating: Found" >> /var/www/test/test/newlyadded.txt
            echo "${cyan}Rating: $rating/10${endline}"
        fi


    #Filtering description
    overview=$(echo "$data" | jq '.results[0] .overview' | tr -d "\"")

        if [ -z "$overview" ]
        then
            echo "${red}Error finding description${endline}"
            echo "  Error finding description" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Overview: Found" >> /var/www/test/test/newlyadded.txt        
            tput bold; echo "${green}Overview: ${endline}"
            echo "${green}$overview${endline}"
            echo " "
        fi

    #Filtering show id
    id=$(echo "$data" | jq '.results[0] .id' | tr -d "\"")
    
        if [ -z "$id" ]
        then
            echo "${red}Error finding id${endline}" 
            echo "  Error finding id" >> /var/www/test/test/newlyadded.txt
        else
            echo "  TmDB ID: Found" >> /var/www/test/test/newlyadded.txt
            echo "${cyan}TmDB ID: $id${endline}"
        fi

    #Executes id search API call
    iddata=$(idquery)

    #Filtering youtube url key
    youtube1=$(echo "$iddata" | jq '.. | .key? // empty' | tr -d "\"" ) 
    youtube=$(echo $youtube1 | awk '{print $1;}')
    
        if [ -z "$youtube" ]
        then
            echo "${red}Error finding trailer${endline}"
            echo "  Error finding trailer" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Trailer: Found" >> /var/www/test/test/newlyadded.txt
            echo "${green}Trailer path (on youtube): $youtube ${endline}"
        fi
    
    #Filtering seasons
    seasons=$(echo "$iddata" | jq '.number_of_seasons' | tr -d "\"")

        if [[ -z "$seasons" || $seasons == "null" ]]
        then
            echo "${red}Error finding number of Seasons${endline}"
            echo "  Error finding number of Seasons" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Seasons: Found" >> /var/www/test/test/newlyadded.txt
            echo "${green}$seasons Season(s) ${endline}"
        fi

    #Encoding path to url
    pathurl=$(echo "$shows" |  sed 's/ /%20/g')
    
# # # # Images # # # #

    #Filtering poster url
	poster=$(echo "$data" | jq '.results[0] .poster_path' | tr -d "\"")
        
        if [ -z "$poster" ]
        then
            echo "${red}Error finding poster${endline}"
            echo "  Error finding poster" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Poster: Found" >> /var/www/test/test/newlyadded.txt
            echo "${cyan}Poster path: $poster ${endline}"
        fi

	#Filtering backdrop url
	backdrop=$(echo "$data" | jq '.results[0] .backdrop_path' | tr -d "\"")
    
        if [ $backdrop == "null" ]
        then
            echo "${red}Error finding backdrop${endline}"
            echo "  Error finding backdrop" >> /var/www/test/test/newlyadded.txt
        else
            echo "  Backdrop: Found" >> /var/www/test/test/newlyadded.txt
            echo "${green}Backdrop path: $backdrop ${endline}"
        fi

    #Downloading posters to ../mov/SHOW_FOLDER/
    curl -s http://image.tmdb.org/t/p/w154$poster --create-dirs -o /var/www/strm.bluetables.space/direct/mov/poster/"$poster"


    #Downloading backdrop to ../mov/
    curl -s http://image.tmdb.org/t/p/original$backdrop --create-dirs -o /var/www/strm.bluetables.space/direct/mov/"$shows"/backdrop.jpg

    insertIntoPage() {

        #Checks if entry exists in index.php
        check="/var/www/strm.bluetables.space/direct/mov/unsorted.txt"
        if grep -q "$name" "$check";
        then
            echo "${red}Poster entry exists${endline}"
            echo " " >> /var/www/test/test/newlyadded.txt
            echo "  Poster entry exists" >> /var/www/test/test/newlyadded.txt
            return
        else
            #Adding newly added entry into index page of Shows
            echo >> /var/www/strm.bluetables.space/direct/mov/unsorted.txt
            
            #Writing to temp file for sorting
            echo "<a href="\"$shows\""><img src="\"../mov/poster$poster\"" alt="\"$name\""></a>" >> /var/www/strm.bluetables.space/direct/mov/unsorted.txt

            #Sorts A-Z for nicer viewing into new file which is read by Shows/index.php 
            sort /var/www/strm.bluetables.space/direct/mov/unsorted.txt > /var/www/strm.bluetables.space/direct/mov/final.txt
            
            echo "  Poster entry added and sorted" >> /var/www/test/test/newlyadded.txt
        fi
    }

    #Calls the function to insert poster into Shows/index.php
    insertIntoPage



    
    #Makes mov/* folders executable (755) as curl making directories make them inaccessible 
    chmod 755 -R /var/www/strm.bluetables.space/direct/mov/

    #Writes a HEADER file with the information directly into the show's directory

cat << EOF > /var/www/strm.bluetables.space/direct/Shows/"$shows"/HEADER.md
# <b style="font-size: 30px">$name<span style="color: #9d9e9d"> ($year)</span></b>

<b><center>
    <span style="color: #9d9e9d">
       $network
    </span> 
    <b style="font-size: 19px">
        $seasons Season(s)
    </b> 
        &#9679; &#11088; 
    <span style="color: #9d9e9d">
        $rating/10
    </span>
</center></b>

<center><p style="color: #ffca38; font-size: 21px; margin-bottom:20px;">
    Overview
</p></center>


<a href="" onclick="window.open('https://www.youtube.com/embed/$youtube','name','width=720,height=480')">
    <center style="font-size: 19px; margin-bottom:20px;">
        &#9654; Play Trailer 
    </center>
</a>

<center><p style="margin: 0 10% 0 10%; line-height: 30px;">
    $overview
</p></center>
EOF

#Checks if HEADER File is actually generated and placed in folder
checkHeader() {
    if [ -f "/var/www/strm.bluetables.space/direct/Shows/"$shows"/HEADER.md" ]; then
        echo "HEADER file generated for $name"
        echo "HEADER.md: Generated" >> /var/www/test/test/newlyadded.txt
    else
        echo "${red}Error Generating HEADER.md${endline}"
        echo "  Error Generating HEADER.md" >> /var/www/test/test/newlyadded.txt
    fi
}

#Calls checkHeader
checkHeader

echo "------------------------------" >> /var/www/test/test/newlyadded.txt
echo " " >> /var/www/test/test/newlyadded.txt

sleep 2
tput bold; echo "${purple}TV Show successfully added!${endline}"
