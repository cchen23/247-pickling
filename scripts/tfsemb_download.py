import os

from transformers import AutoModelForCausalLM, AutoModelForSeq2SeqLM, AutoTokenizer

CAUSAL_MODELS = [
    "gpt2",
    "gpt2-large",
    "gpt2-xl",
    "EleutherAI/gpt-neo-125M",
    "EleutherAI/gpt-neo-1.3B",
    "EleutherAI/gpt-neo-2.7B",
    "EleutherAI/gpt-neox-20b",
    "facebook/opt-125m",
    "facebook/opt-350m",
    "facebook/opt-1.3b",
    "facebook/opt-2.7b",
    "facebook/opt-6.7b",
    "facebook/opt-30b",
]
SEQ2SEQ_MODELS = ["facebook/blenderbot_small-90M"]

# TODO: Add MLM_MODELS (Masked Language Models)


def download_tokenizer_and_model(
    CACHE_DIR, tokenizer_class, model_class, model_name, local_files_only
):
    print("Downloading model")
    model = model_class.from_pretrained(
        model_name,
        output_hidden_states=True,
        cache_dir=CACHE_DIR,
        local_files_only=local_files_only,
    )

    print("Downloading tokenizer")
    tokenizer = tokenizer_class.from_pretrained(
        model_name,
        add_prefix_space=True,
        cache_dir=CACHE_DIR,
        local_files_only=local_files_only,
    )

    return (model, tokenizer)


def download_neox_model(
    # NOTE: This is a special case for gpt-neox-20b for a shortwhile
    CACHE_DIR,
    tokenizer_class,
    model_class,
    model_name,
    local_files_only=False,
):
    model_dir = os.path.join(CACHE_DIR, model_name)

    if local_files_only:
        if os.path.exists(model_dir):
            download_tokenizer_and_model(
                CACHE_DIR, tokenizer_class, model_class, model_dir, local_files_only
            )
        else:
            print(f"Model directory {model_dir} does not exist")
            exit(1)
    else:
        try:
            if "tiger" in os.uname().nodename:
                os.system("module load git")
            os.system(f"cd {CACHE_DIR} && git lfs install")
            os.system("git clone https://huggingface.co/EleutherAI/gpt-neox-20b")
        except:
            # FIXME: Raise appropriate exception
            print("Possible git lfs version issues")
    exit()


def set_cache_dir():
    CACHE_DIR = os.path.join(os.path.dirname(os.getcwd()), ".cache")
    os.makedirs(CACHE_DIR, exist_ok=True)
    return CACHE_DIR


def download_tokenizers_and_models(model_name=None, local_files_only=False):

    CACHE_DIR = set_cache_dir()

    if model_name is None:
        print("Input argument cannot be empty")
        return

    if model_name == "causal" or model_name in CAUSAL_MODELS:
        model_class = AutoModelForCausalLM
        MODELS = CAUSAL_MODELS if model_name == "causal" else [model_name]
    elif model_name == "seq2seq":
        model_class = AutoModelForSeq2SeqLM
        MODELS = SEQ2SEQ_MODELS if model_name == "seq2seq" else [model_name]
    else:
        print("Invalid Model Name")
        exit(1)

    model_dict = {}
    for model_name in MODELS:
        # Special case for gpt-neox-20b
        if model_name == "EleutherAI/gpt-neox-20b":
            download_neox_model(
                CACHE_DIR, AutoTokenizer, model_class, model_name, local_files_only
            )
            continue

        print(f"Model Name: {model_name}")
        model_dict[model_name] = download_tokenizer_and_model(
            CACHE_DIR,
            AutoTokenizer,
            model_class,
            model_name,
            local_files_only=local_files_only,
        )

    return model_dict


if __name__ == "__main__":
    download_tokenizers_and_models("causal", local_files_only=False)
