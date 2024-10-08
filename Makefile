# Instructions
# ------------
# The first time you should run link-data

# For podcast to create a 777 pickle with all electrodes (signal and label)
# glove and gpt2 embeddings:
#   1. create-sig-pickle for 777
#   2. create-pickle for 661
#   3. generate-embeddings for 661 glove and gpt2
#   4. run concatenate-embeddings for 661 glove and gpt2
#   5. run copy-embeddings
#   6. (optionally) run upload-pickle

# For 247
#   1. create-pickle for subject
#   2. generate-embeddings for glove
#   3. generate-embeddings for gpt2
#   4. upload pickle

# Miscellaneous: \
247 Subjects IDs: 625, 676, 7170, and 798 \
Podcast Subjects: 661 662 717 723 741 742 743 763 798 \
777: Is the collection of significant electrodes

# Other Notes:
# For generate-embeddings
# 1. Models greater than 6.7B parameters need a GPU with more than 40GB RAM
# 2. This means currently we cannot run EleutherAI/gpt-neox-20b and 
# facebook/opt-30b using huggingface on della GPUs

# Run all commands in one shell
.ONESHELL:

# NOTE: link data from tigressdata before running any scripts
PRJCT_ID := tfs
# {tfs | podcast}

link-data:
ifeq ($(PRJCT_ID), podcast)
	$(eval DIR_KEY := podcast-data)
else
	$(eval DIR_KEY := conversations-car)
endif
	# create directory
	mkdir -p data/$(PRJCT_ID)
	# delete old symlinks
	find data/$(PRJCT_ID)/ -xtype l -delete
	# create symlinks from original data store
	ln -sf /projects/HASSON/247/data/$(DIR_KEY)/* data/$(PRJCT_ID)/

# settings for target: create-pickle, create-sig-pickle, upload-pickle
%-pickle: CMD := sbatch --job-name=create-pickle-$$sid submit.sh
%-pickle: CMD := python
# {echo | python}
%-pickle: PRJCT_ID := tfs
# {tfs | podcast}
%-pickle: SID_LIST = 676 # 7170 625 798
# {625 676 7170 798 | 661 662 717 723 741 742 743 763 798 | 777}

create-pickle:
	mkdir -p logs
	for sid in $(SID_LIST); do \
		$(CMD) scripts/tfspkl_main.py \
			--project-id $(PRJCT_ID) \
			--subject $$sid \
			--user-id $(USER);
	done

# create pickle of significant electrodes (just for podcast)
create-sig-pickle:
	mkdir -p logs
	$(CMD) scripts/tfspkl_main.py \
			--project-id $(PRJCT_ID) \
			--sig-elec-file all-electrodes2.csv

# upload pickles to google cloud bucket
# on bucket we use 247 not tfs, so manually adjust as needed
# upload-pickle: pid=247
upload-pickle: pid=podcast
upload-pickle:
	for sid in $(SID_LIST); do \
		gsutil -m rsync -rd results/$(PRJCT_ID)/$$sid/pickles/ gs://247-podcast-data/$(pid)-pickles/$$sid; \
	done

# upload raw data to google cloud bucket
upload-data:
	gsutil -m rsync -rd data/tfs/676 gs://247-podcast-data/247-data/676/
	gsutil -m rsync -rd data/tfs/625 gs://247-podcast-data/247-data/625/

# download pickles from google cloud bucket
download-247-pickles:
	mkdir -p results/{625,676}
	gsutil -m rsync -x "^(?!.*625).*" gs://247-podcast-data/247-pickles/ results/625/
	gsutil -m rsync -x "^(?!.*676).*" gs://247-podcast-data/247-pickles/ results/676/

## settings for targets: generate-embeddings, concatenate-embeddings
%-embeddings: PRJCT_ID := tfs
# {tfs | podcast}
%-embeddings: SID = 7170
# {625 | 676 | 7170 | 798 | 661} 
%-embeddings: CONV_IDS = $(shell seq 1 24) 
# {54 for 625 | 78 for 676 | 1 for 661 | 24 for 7170 | 15 for 798}
%-embeddings: PKL_IDENTIFIER := full
# {full | trimmed | binned}
%-embeddings: EMB_TYPE := gpt2-xl
# {"gpt2", "gpt2-large", "gpt2-xl", \
"EleutherAI/gpt-neo-125M", "EleutherAI/gpt-neo-1.3B", "EleutherAI/gpt-neo-2.7B", \
"EleutherAI/gpt-neox-20b", \
"facebook/opt-125m", "facebook/opt-350m", "facebook/opt-1.3b", \
"facebook/opt-2.7b", "facebook/opt-6.7b", "facebook/opt-30b", \
"facebook/blenderbot_small-90M"}
%-embeddings: CNXT_LEN := 1024
%-embeddings: LAYER := last
# {'all' for all layers | 'last' for the last layer | (list of) integer(s) >= 1}
# Note: embeddings file is the same for all podcast subjects \
and hence only generate once using subject: 661
%-embeddings: JOB_NAME = $(subst /,-,$(EMB_TYPE))
%-embeddings: CMD = sbatch --job-name=$(SID)-$(JOB_NAME)-cnxt-$$cnxt_len-$$conv_id submit.sh
# {echo | python | sbatch --job-name=$(SID)-$(JOB_NAME)-cnxt-$$cnxt_len submit.sh}

# 38 and 39 failed

# generate-base-for-embeddings: Generates the base dataframe for embedding generation
generate-base-for-embeddings:
	python scripts/tfsemb_LMBase.py \
			--project-id $(PRJCT_ID) \
			--pkl-identifier $(PKL_IDENTIFIER) \
			--subject $(SID) \
			--embedding-type $(EMB_TYPE) \
			--user-id $(USER);

# generates embeddings (for each conversation separately)
generate-embeddings: 
	mkdir -p logs
	for cnxt_len in $(CNXT_LEN); do \
		for conv_id in $(CONV_IDS); do \
			 $(CMD) scripts/tfsemb_main.py \
				--project-id $(PRJCT_ID) \
				--pkl-identifier $(PKL_IDENTIFIER) \
				--subject $(SID) \
				--conversation-id $$conv_id \
				--embedding-type $(EMB_TYPE) \
				--layer-idx $(LAYER) \
				--context-length $$cnxt_len \
				--user-id $(USER);
		done; \
	done; \

# concatenate embeddings from all conversations
concatenate-embeddings:
	for cnxt_len in $(CNXT_LEN); do \
		python scripts/tfsemb_concat.py \
			--project-id $(PRJCT_ID) \
			--pkl-identifier $(PKL_IDENTIFIER) \
			--subject $(SID) \
			--embedding-type $(EMB_TYPE) \
			--context-length $$cnxt_len \
			--user-id $(USER);
	done;

# Podcast: copy embeddings to other subjects as well
copy-embeddings:
	fn=results/podcast/661/pickles/embeddings
	for sid in 662 717 723 741 742 763 798 777; do \
		cp -rpf $$fn $$(echo $$fn | sed "s/661/$$sid/g"); \
	done; \


# Download huggingface models to cache (before generating embeddings)
# This target needs to be run on the head node
cache-models: MODEL := causal
# {causal | seq2seq | mlm | or any model name specified in EMB_TYPE comments}
cache-models:
	python -c "from scripts import tfsemb_download; tfsemb_download.download_tokenizers_and_models(\"$(MODEL)\")"
