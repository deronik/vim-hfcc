if !has('python3')
  echo "Python 3 support is required for HFCC plugin"
  finish
endif

python3 << EndPython3
import vim
try:
    import requests
except ImportError:
    print("Error: requests module not found. Please install requests module")
    raise

def get_url(model="bigcode/starcoder"):
    return f"https://api-inference.huggingface.co/models/{model}"

def current_lines(start, end):
    lines = vim.eval('getline({}, {})'.format(start, end))
    return "\n".join(lines)


def replace_current_lines(start, end, new_text):
    """ replace text in buffer marked by visual selection <> """
    new_lines = new_text.split("\n")
    buf = vim.current.buffer
    buf[start-1:end] = new_lines


def get_prediction(_input):
    token = vim.eval("g:hfcc_token")
    if not token:
        print("please provide hfcc_token")
    headers = {
        "Content-type": "Application/json",
        "Authorization": f"Bearer {token}"
    }
    settings = {
        "max_new_tokens": int(vim.eval("g:hfcc_max_tokens")),
        "temperature": float(vim.eval("g:hfcc_temperature")),
        "top_p": float(vim.eval("g:hfcc_top_p")),
        "do_sample": True,
        "stop": [vim.eval("g:hfcc_stoptoken"), ]
    }
    url = get_url(vim.eval("g:hfcc_model"))
    body = {"inputs": _input, "parameters": settings}
    response = requests.post(url, headers=headers, json=body)
    if response.status_code != 200:
        print("failed to retrive prediction")
        return None
    result = response.json()
    if len(result)!=1:
        print("unexpected result")
        return None
    return result[0]['generated_text']


def remove_stop_token(prediction):
    if vim.eval("g:hfcc_stoptoken"):
        return prediction.replace(vim.eval("g:hfcc_stoptoken"), "")
    return suffix_prediciton


def hfcc_selected(start=None, end=None):
    if not start and not end:
        # try to get last visual block
        buf = vim.current.buffer
        if not buf.mark('<') or not buf.mark('>'):
            print("selected block isn't found")
            return None
        start, _ = buf.mark('<')
        end, _ = buf.mark('>')
    start = int(start)
    end = int(end)
    lines = current_lines(start, end)
    if not lines:
        print("selected block isn't found")
        return
    prediction = get_prediction(lines)
    if prediction:
        clean_prediction = remove_stop_token(prediction)
        replace_current_lines(start, end, clean_prediction)


def hfcc_current_buffer():
    buf = vim.current.buffer
    lines = "\n".join(buf[:])
    prediction = get_prediction(lines)
    if prediction:
        clean_prediction = remove_stop_token(prediction)
        buf[:] = clean_prediction.split('\n')


def hfcc_in_place():
    current_line_index = vim.current.window.cursor[0]
    buf = vim.current.buffer
    lines = list(buf)
    lines[current_line_index-1]+="<fim_suffix>\n"
    prediction_input = "<fim_prefix>\n"+"\n".join(lines)+"\n<fim_middle>"
    prediction = get_prediction(prediction_input)
    if not prediction:
        return None
    suffix_prediciton = prediction.split("<fim_middle>")[-1]
    clean_prediction = remove_stop_token(suffix_prediciton)
    prediction_lines = clean_prediction.split("\n")
    buf[current_line_index-1]+=prediction_lines[0]
    buf[current_line_index:current_line_index] = prediction_lines[1:]

EndPython3

function hfcc#hfcc_selected() range
    if a:firstline != 0 && a:lastline != 0
        let start = a:firstline
        let end = a:lastline
        :py3 hfcc_selected(vim.eval('start'), vim.eval('end'))
    else
        :py3 hfcc_selected()
    endif
endfunction
function hfcc#hfcc_current_buffer()
    :py3 hfcc_current_buffer()
endfunction
function hfcc#hfcc_in_place()
    :py3 hfcc_in_place()
endfunction
