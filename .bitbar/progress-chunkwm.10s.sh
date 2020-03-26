#!/bin/sh
# add this to your bitbar directory
# don't forget to chmod +x


export PATH=/usr/local/bin:$PATH

if [[ "$1" = "stop" ]]; then
  brew services stop koekeishiya/formulae/yabai
  brew services stop skhd
fi

if [[ "$1" = "restart" ]]; then
  brew services restart koekeishiya/formulae/yabai
  brew services restart skhd
fi

# width and characters for the progress bars
# feel free to configure these
width=20
fill_char="█"
empty_char="▁"


# bitbar parameters
# use a monospace font if you want the percentages to be right-aligned
bitbar="size=12 color=#123248 font='Avenir'"
## See Font Book.app's Fixed Width collection for what you can use
## you can also download this font for free and drag it into Font Book.app.
## https://github.com/belluzj/fantasque-sans/releases/latest


# all of the calculations are done using unix timestamps from date(1)
# mac uses bsd's date(1)
# whenever we set a date, make sure to add -j so it doesn't change the clock
# we use `date -j %m%d0000 +%s` to get the start timestamp, %Y is implied
# then we use `date -jr $start -v +1y/+1m/+1d +%s` to get the ending timestamp
# then we calculate the percentage with (now - start) / (end - start)

now=$(date +%s)


###############################################
###### USING FIRST WAY TO CALCULATE DATE ######
###############################################

Y=$(date +%Y)
Y_start=$(date -j 01010000 +%s)
Y_end=$(date -jr $Y_start -v +1y +%s)
Y_progress=$(
    echo "($now - $Y_start) * 100 / ($Y_end - $Y_start)" | bc -l
)


m=$(date +%m)
m_start=$(date -j $(date +%m)010000 +%s)
m_end=$(date -jr $m_start -v +1m +%s)
m_progress=$(
    echo "($now - $m_start) * 100 / ($m_end - $m_start)" | bc -l
)

d=$(date +%d)
d_start=$(date -j $(date +%m%d)0000 +%s)
d_end=$(date -jr $d_start -v +1d +%s)
d_progress=$(
    echo "($now - $d_start) * 100 / ($d_end - $d_start)" | bc -l
)


## ADDING MY OWN DETAILS

# Work day between 6am and 7pm
d_start_work=$(date -jr $d_start -v +6H +%s)
d_end_work=$(date -jr $d_start_work -v +12H +%s)
d_shower=$(date -jr $d_start_work -v +13H +%s)
d_bed=$(date -jr $d_start_work -v +15H +%s)
d_end_work_left=$(date -jr $d_start_work -v +12H +%r)
d_progress_work=$(
    echo "($now - $d_start_work) * 100 / ($d_end_work - $d_start_work)" | bc -l
)

# Extra time between 7pm and 9:00pm
d_start_extra=$(date -jr $d_start -v +19H +%s)
d_end_extra=$(date -jr $d_start_extra -v +2H +%s)
d_progress_extra=$(
    echo "($now - $d_start_extra) * 100 / ($d_end_extra - $d_start_extra)" | bc -l
)



################################################
###### USING RECENT WAY TO CALCULATE DATE ######
################################################


# Time in hours left
# Source found at https://www.unix.com/shell-programming-and-scripting/171674-displaying-time-left-end-day-week-month.html


date_arr=( $(date '+%H %M %S %u %d') )

hour_end_of_work=$(echo "17-${date_arr[0]}"| bc)
hour_start_shower=$(echo "18-${date_arr[0]}"| bc)
hour_start_bed=$(echo "20-${date_arr[0]}"| bc)
end_min=$(echo "59-${date_arr[1]}"| bc)
end_sec=$(echo "60-${date_arr[2]}"| bc)

time_end_of_work="${hour_end_of_work}h ${end_min}m"
time_start_shower="${hour_start_shower}h ${end_min}m"
time_start_bed="${hour_start_bed}h ${end_min}m"


print_time_before_end_of_work=$(
    echo "$time_end_of_work left" 
)

print_time_before_shower=$(
    echo "$time_start_shower before shower" 
)

print_time_before_bed=$(
    echo "$time_start_bed before bed" 
)

# padding to align progress bar and text
# Y-m-d = 10 + 2 spaces + 2 digits + percent sign = 15
# progress bar width - 15 = padding
padding=$(printf %$((width-15))s "")


# round function
round() { printf %.0f "$1"; }

# progress bar display function
progress() {
    filled=$(round $(echo "$1 * $width / 100" | bc -l))
    empty=$((width - filled))
    # repeat the characters using printf
    printf "$fill_char%0.s" $(seq $filled)
    printf "$empty_char%0.s" $(seq $empty)
}


# output to bitbar
# first line
if [[ $now < $d_end_work ]]
then
	echo "$print_time_before_end_of_work"
    #  $(round $d_progress_work)% | $bitbar size=14"
    echo ---
    # day work + progress bar
    echo "$Y-$m-$d $padding $(round $d_progress_work)%   | $bitbar"
    echo "$(progress $d_progress_work)                   | $bitbar"
    echo ---
elif [[ $now < $d_shower ]]
then
	echo "$print_time_before_shower"
    # echo "Extra time: $(round $d_progress_extra)% | $bitbar size=14"
    echo ---
elif [[ $now < $d_bed ]]
then
    echo "$print_time_before_bed"
    # echo "Extra time: $(round $d_progress_extra)% | $bitbar size=14"
    echo ---
else
    echo "You should be in bed"
fi
# echo "$(chunkc tiling::query --desktop id):$(chunkc tiling::query --desktop mode) | length=5"
echo "---"
echo "Restart yabai & skhd | bash='$0' param1=restart terminal=false"
echo "Stop yabai & skhd | bash='$0' param1=stop terminal=false"
echo "---"
echo "If I go to bed now, I will wake up around $(date -v +8H +%R) | $bitbar size=14"
