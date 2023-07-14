# Vim Hugging Face Code Completion Plugin (In Development)

## Install
Create and get your API token from here https://huggingface.co/settings/tokens.

### Vundle
Your vim have to be builded with python3, also you have to install `requests` module
After it you can install plugin through Vundle
```vim
 Plugin 'deronik/vim-hfcc'
```

## Setup
Provide configuration variables in your vim config, below you can see sample config
```vim
" your token for huggingface
g:hfcc_token='<token>'
" maximum new token in response
g:hfcc_max_tokens=60
" tempearature (confidence level of prediction)
g:hfcc_temperature=0.2
" top_p sampling chooses
g:hfcc_top_p=0.95
```

## Usage
- :HFCCSelection - apply code completetion for last selected segment
- :HFCCAll - apply code completetion for full file
- :HFCCInPlace - apply code completeion to current cursor place
