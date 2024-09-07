import numpy as np
import os
import pickle

context_lengths = ['0008', '0032', '0064', '0256', '1024']

for sid in [625, 676, 7170, 798]:
    sid_embeds_dir = f"/scratch/gpfs/cc27/results/tfs/{sid}/embeddings/gpt2-xl/full/"

    base_df_filepath = os.path.join(sid_embeds_dir, 'base_df.pkl')
    if not os.path.exists(base_df_filepath):
        base_df_filepath = f"/scratch/gpfs/cc27/results/tfs/{sid}/pickles/embeddings/gpt2-xl/full/base_df.pkl"
    with open(base_df_filepath, 'rb') as f:
        base_df = pickle.load(f)

    convo_names = np.unique(base_df['conversation_name'])
    for context_length in context_lengths:
        print(f"Checking for context {context_length} for sid {sid}")
        context_folder = os.path.join(sid_embeds_dir, f'cnxt_{context_length}', 'layer_48')
        if not os.path.exists(context_folder):
            print(f"MISSING {context_folder}")
        else:
            saved_embeds_files = os.listdir(context_folder)
            saved_embeds_file_keys = [fname.split(".")[0] for fname in saved_embeds_files]
            print(f"missing files: {set(convo_names) - set(saved_embeds_file_keys)}")
            print(f"extra files: {set(saved_embeds_file_keys) - set(convo_names)}")
