python3 << EndPython3
import vim
import requests


def get_url(model="bigcode/starcoder"):
    return f"https://api-inference.huggingface.co/models/{model}"


def current_lines():
    """ get last mark visual selection <> """
    buf = vim.current.buffer
    if not buf.mark('<') or not buf.mark('>'):
        return None
    lnum1, col1 = buf.mark('<')
    lnum2, col2 = buf.mark('>')
    lines = vim.eval('getline({}, {})'.format(lnum1, lnum2))
    lines[0] = lines[0][col1:]
    lines[-1] = lines[-1][:col2]
    return "\n".join(lines)


def replace_current_lines(new_text):
    """ replace text in buffer marked by visual selection <> """
    new_lines = new_text.split("\n")
    buf = vim.current.buffer
    lnum1, col1 = buf.mark('<')
    lnum2, col2 = buf.mark('>')
    buf[lnum1-1:lnum2]=new_lines


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
        # "stop": vim.eval("g:hfcc_stoptoken")
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


def hfcc_selected():
    lines = current_lines()
    if not lines:
        print("selected block isn't found")
        return
    prediction = get_prediction(lines)
    if prediction:
        replace_current_lines(prediction)


def hfcc_current_buffer():
    buf = vim.current.buffer
    lines = "\n".join(buf[:])
    prediction = get_prediction(lines)
    if prediction:
        buf[:] = prediction.split('\n')

EndPython3

function hfcc#hfcc_selected()
    :py3 hfcc_selected()
endfunction
function hfcc#hfcc_current_buffer()
    :py3 hfcc_current_buffer()
endfunction
