import json
from nltk.tokenize.casual import TweetTokenizer

tokenizer = TweetTokenizer()
review_filenames = [
	'gen_food_reviews_1.json',
	'gen_food_reviews_2.json',
	'gen_food_reviews_3.json',
	'gen_food_reviews_4.json',
	'gen_food_reviews_5.json'
]
MENU_KEY = 'food'
REVIEW_TEXT_KEY = 'text'
REVIEW_STARS_KEY = 'stars'
POS_LABEL = 'pos'
NEG_LABEL = 'neg'

# Utility methods
def get_stopwords():
	res = set()
	for line in open('stopwords','r'):
		res.add(line.strip())
	return res

##########################

def create_dishmap():
	initial_review_count = {POS_LABEL: 0, NEG_LABEL: 0}
	dishmap = {}
	business_fn = 'gen_business_id_menu.json'
	stopwords = get_stopwords()
	for line in open(business_fn):
		bizdata = json.loads(line.strip())
		menu = bizdata.get(MENU_KEY,[])
		for item in menu:
			name = item.strip().encode('utf-8')
			if name in stopwords or len(name) < 3:
				continue
			dishmap[name] = dict(initial_review_count)
	return dishmap

def parse_reviews():
	dishmap = create_dishmap()
	writer = open('food_related_reviews.json', 'w')
	for fn in review_filenames:
		ct = 0
		for line in open(fn):
			ct += 1
			if ct > 50: break
			review_json = json.loads(line.strip())
			stars = review_json.get(REVIEW_STARS_KEY)
			text = review_json[REVIEW_TEXT_KEY].encode('utf-8')
			tokens = tokenizer.tokenize(text)
			tokens = [t.strip() for t in tokens]
			for length in xrange(1,6):
				for i in xrange(len(tokens)+1-length):
					phrase = ' '.join(tokens[i:i+length])
					if phrase in dishmap:
						print phrase

if __name__ == '__main__':
	parse_reviews()
