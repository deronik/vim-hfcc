if !exists("g:hfcc_max_tokens")
    let g:hfcc_max_tokens = 60
endif
if !exists("g:hfcc_temperature")
    let g:hfcc_temperature = 0.2
endif
if !exists("g:hfcc_top_p")
    let g:hfcc_top_p = 0.95
endif
if !exists("g:hfcc_stoptoken")
    let g:hfcc_stoptoken = '<|endoftext|>'
endif
if !exists("g:hfcc_model")
    let g:hfcc_model = "bigcode/starcoder"
endif
if !exists("g:hfcc_token")
    let g:hfcc_token = ""
endif

command! HFCCSelection :call hfcc#hfcc_selected()
command! HFCCAll :call hfcc#hfcc_current_buffer()
