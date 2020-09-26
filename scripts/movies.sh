#!/usr/bin/bash

    # Script written by Ahmad Usayd (2020)
    # jq is required to parse JSON 
    # curl is used to call the API
    # The Movie Database API is used, Please add in your API Key from their website below:
    apikey=""


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

    echo "${green}Enter the name of the Movie: ${red}[Make sure the name is exactly as the path or else it will break]${cyan}"
    read -r path
    echo "${endline}"

    #Search API call for the query
    function query 
    {
        curl -s --request GET \
        --url "https://api.themoviedb.org/3/search/movie?year=$year&query=$titleurl&language=en-US&api_key=a359adb0d308edb4b532a6dedc37a2e5" \
        --header 'content-type: application/json'
    }
    
    #Movie ID API call for the query
    function idquery 
    {
        curl -s --request GET \
        --url "https://api.themoviedb.org/3/movie/$id?language=en-US&api_key=a359adb0d308edb4b532a6dedc37a2e5&append_to_response=videos" \
        --header 'content-type: application/json'
    }

    #Remove brackets for clean search [title]
    cleanpath=$(echo $path | sed -e 's/([^()]*)//g')
    echo $cleanpath >> done.txt
    
    #Convert to URL by changing spaces into %20
	titleurl=${cleanpath// /%20}

    #Find the year of each movie from each line
    year=$(echo $path | sed 's/.*(\(.*\))/\1/')
        
    #Search API call
    data=$(query)


    #Filtering Name
	name=$(echo "$data" | jq '.results[0] .title' | tr -d "\"")
    

    #Filtering release date
    rdate=$(echo "$data" | jq '.results[0] .release_date' | tr -d "\"")
    qyear=$(echo $rdate | cut -c1-4)

    if [[ $name == "null" ]]
    then
        tput bold; echo "${red}No matches found${endline}"
        exit 1;
    fi
    tput bold; echo "${green}Result found: $name ${endline}(${cyan}$qyear${endline})"
    echo "Correct Result? (Y/n) ${cyan}"
        read -n 1 -r 
    #echo " "
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            exit 1;
        fi
    
    echo $name >> newlyadded.txt
    
    tput bold; echo "${purple}$name${endline}"

    #Filtering user rating
    rating=$(echo "$data" | jq '.results[0] .vote_average' | tr -d "\"")
    
        if [ -z "$rating" ]
        then
            echo "${red}Error finding rating${endline}"
            echo "  Error finding rating" >> newlyadded.txt
        else
            echo "  Rating: Found" >> newlyadded.txt
            echo "${cyan}Rating: $rating/10${endline}"
        fi


    #Filtering description
    overview=$(echo "$data" | jq '.results[0] .overview' | tr -d "\"")

        if [ -z "$overview" ]
        then
            echo "${red}Error finding description${endline}"
            echo "  Error finding description" >> newlyadded.txt
        else
            echo "  Overview: Found" >> newlyadded.txt        
            tput bold; echo "${green}Overview: ${endline}"
            echo "${green}$overview${endline}"
            echo " "
        fi

    #Filtering movie id
    id=$(echo "$data" | jq '.results[0] .id' | tr -d "\"")

        if [ -z "$id" ]
        then
            echo "${red}Error finding id${endline}" 
            echo "  Error finding id" >> newlyadded.txt
        else
            echo "  TmDB ID: Found" >> newlyadded.txt
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
            echo "  Error finding trailer" >> newlyadded.txt
        else
            echo "  Trailer: Found" >> newlyadded.txt
            echo "${green}Trailer path (on youtube): $youtube ${endline}"
        fi

    #Filtering runtime
    rtime=$(echo "$iddata" | jq '. .runtime' | tr -d "\"")

        if [[ -z "$rtime" || $rtime == "null" ]]
        then
            echo "${red}Error finding movie runtime${endline}"
            echo "  Error finding runtime" >> newlyadded.txt
        else
            echo "  Runtime: Found" >> newlyadded.txt
            echo "${green}$rtime minutes ${endline}"
        fi

    #Filtering tagline (Unused as most movies do not have a tagline)
    tagline=$(echo "$iddata" | jq '.two[1] .tagline // empty' | tr -d "\"")

    #Converting runtime to hours and minutes
    ((hour=$rtime/60))
    ((min=$rtime-$hour*60))


    #Encoding path to url
    pathurl=$(echo "$path" |  sed 's/ /%20/g')
    

    # # # Images # # #

	#Filtering poster url
	poster=$(echo "$data" | jq '.results[0] .poster_path' | tr -d "\"")

        if [ -z "$poster" ]
        then
            echo "${red}Error finding poster${endline}"
            echo "  Error finding poster" >> newlyadded.txt
        else
            echo "  Poster: Found" >> newlyadded.txt
            echo "${cyan}Poster path: $poster ${endline}"
        fi

	#Filtering backdrop url
	backdrop=$(echo "$data" | jq '.results[0] .backdrop_path' | tr -d "\"")

        if [ $backdrop == "null" ]
        then
            echo "${red}Error finding backdrop${endline}"
            echo "  Error finding backdrop" >> newlyadded.txt
        else
            echo "  Backdrop: Found" >> newlyadded.txt
            echo "${green}Backdrop path: $backdrop ${endline}"
        fi
        
    #Downloading posters to ../mov/MOVIE_FOLDER/
    curl -s http://image.tmdb.org/t/p/w154$poster --create-dirs -o /var/www/strm.bluetables.space/direct/mov/poster/"$poster"

    #Downloading backdrop to ../mov/
    curl -s http://image.tmdb.org/t/p/original$backdrop --create-dirs -o /var/www/strm.bluetables.space/direct/mov/"$path"/backdrop.jpg

    # # # Writing to HTML and MD files # # #

    insertIntoPage() {

        #Checks if entry exists in index.php
        check="/var/www/strm.bluetables.space/direct/mov/unsortedmovies.txt"
        if grep -q "$name" "$check";
        then
            echo "${red}Poster entry exists${endline}"
            echo " " >> newlyadded.txt
            echo "  Poster entry exists" >> newlyadded.txt
            sort /var/www/strm.bluetables.space/direct/mov/unsortedmovies.txt > /var/www/strm.bluetables.space/direct/mov/finalmovies.txt
            return
        else
            #Adding newly added entry into index page of Movies
            echo >> /var/www/strm.bluetables.space/direct/mov/unsortedmovies.txt
            
            #Writing to temp file for sorting
            echo "<a href="\"$path\""><img src="\"../mov/poster$poster\"" alt="\"$name\""></a>" >> /var/www/strm.bluetables.space/direct/mov/unsortedmovies.txt

            #Sorts A-Z for nicer viewing into new file which is read by Movies/index.php 
            sort /var/www/strm.bluetables.space/direct/mov/unsortedmovies.txt > /var/www/strm.bluetables.space/direct/mov/finalmovies.txt
	    
	    echo "  Poster entry added and sorted" >> newlyadded.txt
        fi
    }

    #Calls the function to insert/check poster for Movies/index.php
    insertIntoPage


    echo "------------------------------" >> newlyadded.txt
    echo " " >> newlyadded.txt
    
    #Makes mov/* folders executable (755) as curl making directories make them inaccessible 
    chmod 755 -R /var/www/strm.bluetables.space/direct/mov/

    #Writes a HEADER file with the information directly into the movie's directory

cat << EOF > /var/www/strm.bluetables.space/direct/Movies/"$path"/HEADER.md
# <b style="font-size: 30px">$cleanpath<span style="color: #9d9e9d"> ($year)</span></b>

<b><center>
    <span style="color: #9d9e9d">
        $rdate
    </span> &#9679; 
    <b style="font-size: 21px">
        $hour
    </b>h 
    <b style="font-size: 21px">
        $min
    </b>m 
        &#9679; &#11088; 
    <span style="color: #9d9e9d">
        $rating/10
    </span>
</center></b>

<a href="" onclick="window.open('https://www.youtube.com/embed/$youtube ','name','width=1280,height=720')">
    <center style="font-size: 19px; margin-bottom:20px;">
        &#9654; Play Trailer 
    </center>
</a>

<center><p style="color: #ffca38; font-size: 21px; margin-bottom:20px;">
    Overview
</p></center>

<center><p style="margin: 0 10% 0 10%; line-height: 30px;">
    $overview
</p></center>
EOF

echo "HEADER file generated for $name"
echo "HEADER.md: Generated" >> newlyadded.txt


tput bold; echo "${purple}Movie successfully added!${endline}"
