#!/bin/sh
# add this to your bitbar directory
# don't forget to chmod +x


export PATH=/usr/local/bin:$PATH

if [[ "$1" = "stop" ]]; then
  brew services stop koekeishiya/formulae/chunkwm
  brew services stop skhd
fi

if [[ "$1" = "restart" ]]; then
  brew services restart koekeishiya/formulae/chunkwm
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




## SHOW BEGIN HERE

# Work day between 6am and 7pm
d_start_work=$(date -jr $d_start -v +6H +%s)
d_end_work=$(date -jr $d_start_work -v +13H +%s)
d_end_work_left=$(date -jr $d_start_work -v +13H +%r)
d_progress_work=$(
    echo "($now - $d_start_work) * 100 / ($d_end_work - $d_start_work)" | bc -l
)

# Extra time between 7pm and 9:00pm
d_start_extra=$(date -jr $d_start -v +19H +%s)
d_end_extra=$(date -jr $d_start_extra -v +2H +%s)
d_progress_extra=$(
    echo "($now - $d_start_extra) * 100 / ($d_end_extra - $d_start_extra)" | bc -l
)

# ($d_end_work - $now)
# Time in hours left


date_arr=( $(date '+%H %M %S %u %d') )

end_hour=$(echo "18-${date_arr[0]}"| bc)
end_min=$(echo "59-${date_arr[1]}"| bc)
end_sec=$(echo "60-${date_arr[2]}"| bc)

#eod="${end_hour}h ${end_min}m ${end_sec}s"
eod="${end_hour}h ${end_min}m"


Y_timeleft=$(
	echo "$eod left" 
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
if [[ $d_start_work < $d_end_work ]]
then
	echo "$Y_timeleft"
    #  $(round $d_progress_work)% | $bitbar size=14"
    echo ---
    # day work + progress bar
    echo "$Y-$m-$d $padding $(round $d_progress_work)%   | $bitbar"
    echo "$(progress $d_progress_work)                   | $bitbar"
    echo ---
else
    echo "Extra time: $(round $d_progress_extra)% | $bitbar size=14"
    echo ---
    # extra time + progress bar
    echo "$Y-$m-$d $padding $(round $d_progress_extra)%   | $bitbar"
    echo "$(progress $d_progress_extra)                   | $bitbar"
    echo ---
fi
echo "$(chunkc tiling::query --desktop id):$(chunkc tiling::query --desktop mode) | length=5"
echo "---"
echo "Restart chunkwm & skhd | bash='$0' param1=restart terminal=false"
echo "Stop chunkwm & skhd | bash='$0' param1=stop terminal=false"
echo "---"
echo "If I go to bed now, I will wake up around $(date -v +8H +%R) | $bitbar size=14"



