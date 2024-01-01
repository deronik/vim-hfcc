if !has('python3')
  echo "Python 3 support is required for HFCC plugin"
  finish
endif

python3 << EndPython3
import vim
import re

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
    """replace text in buffer marked by visual selection <>"""
    new_lines = new_text.split("\n")
    buf = vim.current.buffer
    buf[start - 1 : end] = new_lines


def call_hfcc_api(_input, model):
    token = vim.eval("g:hfcc_token")
    if not token:
        print("please provide hfcc_token")
    headers = {"Content-type": "Application/json", "Authorization": f"Bearer {token}"}
    settings = {
        "max_new_tokens": int(vim.eval("g:hfcc_max_tokens")),
        "temperature": float(vim.eval("g:hfcc_temperature")),
        "top_p": float(vim.eval("g:hfcc_top_p")),
        "do_sample": True,
        "stop": [
            vim.eval("g:hfcc_stoptoken"),
        ],
    }
    url = get_url(vim.eval(model))
    body = {"inputs": _input, "parameters": settings}
    response = requests.post(url, headers=headers, json=body)
    if response.status_code != 200:
        print("failed to retrive prediction")
        return None
    result = response.json()
    if len(result) != 1:
        print("unexpected result")
        return None
    return result[0]['generated_text']


def get_prediction(_input):
    return call_hfcc_api(_input, "g:hfcc_model")


def get_chat(_input):
    return call_hfcc_api(_input, "g:hfcc_chat")


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
    lines[current_line_index - 1] += "<fim_suffix>\n"
    prediction_input = "<fim_prefix>\n" + "\n".join(lines) + "\n<fim_middle>"
    prediction = get_prediction(prediction_input)
    if not prediction:
        return None
    suffix_prediciton = prediction.split("<fim_middle>")[-1]
    clean_prediction = remove_stop_token(suffix_prediciton)
    prediction_lines = clean_prediction.split("\n")
    buf[current_line_index - 1] += prediction_lines[0]
    buf[current_line_index:current_line_index] = prediction_lines[1:]


def _fix_result(query, result):
    try:
        end_of_assist = result.index("<|end|>", len(query))
        end_of_assist += len("<|end|>")
    except ValueError:
        return result
    return result[:end_of_assist]


def _pretty_result(result):
    if result.endswith("<|end|>"):
        # assistance part is ended turn to user
        result += "\n\n<|user|>"
    user_fixed = result.replace("<|user|>", "User: ")
    assist_fixed = user_fixed.replace("<|assistant|>", "Assistant: ")
    end_fixed = assist_fixed.replace("<|end|>", "")
    return end_fixed


def unpretty_buffer(result):
    user_fixed = result.replace("User: ", "<|end|><|user|>")
    assist_fixed = user_fixed.replace("Assistant: ", "<|end|><|assistant|>")
    end_removed = assist_fixed.removeprefix("<|end|>")
    # set <|end|> if last turn is user
    result = re.findall(r"<\|user\|>|<\|assistant\|>", end_removed)
    if result[-1] == "<|user|>":
        return end_removed + "<|end|>"
    return end_removed


def hfcc_chat(params):
    vim.command(":new")
    vim.command(":buffer")
    buffer = vim.current.buffer
    buffer.name = f"HFCC Chat {buffer.number}"
    # set buffer to scratch type
    buffer.options['buftype'] = 'nofile'
    buffer.options['bufhidden'] = 'hide'
    buffer.options['swapfile'] = False
    if not params:
        buffer[:] = ["User: "]
        return
    search_query = "<|user|>" + " ".join(params) + "<|end|>"
    result = get_chat(search_query)
    truncated_result = _fix_result(search_query, result)
    result = _pretty_result(truncated_result)
    buffer[:] = result.split("\n")


def hfcc_chat_load_more():
    buffer = vim.current.buffer
    if "HFCC Chat" not in buffer.name:
        print(f"You have to use it in HFCC Chat buffer {buffer.name}")
        return
    query = unpretty_buffer("\n".join(buffer))
    result = get_chat(query)
    truncated_result = _fix_result(query, result)
    result = _pretty_result(truncated_result)
    buffer[:] = result.split("\n")

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
function hfcc#hfcc_chat( ... )
    let params = []
    for param in a:000
        call add(params, param)
    endfor
    :py3 hfcc_chat(vim.eval("params"))
endfunction
function hfcc#hfcc_chat_load_more()
    :py3 hfcc_chat_load_more()
endfunction
