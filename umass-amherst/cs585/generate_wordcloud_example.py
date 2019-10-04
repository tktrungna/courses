from collections import defaultdict
from wordcloud import WordCloud
from nltk.corpus import stopwords
from nltk.tokenize.casual import TweetTokenizer
import json
import string

TEST_WORD = 'fish sandwich'
fn5 = 'data/gen_food_reviews_5_sentence_withdish_withsentiment.json'
fn4 = 'data/gen_food_reviews_4_sentence_withdish_withsentiment.json'
fn3 = 'data/gen_food_reviews_3_sentence_withdish_withsentiment.json'
fn2 = 'data/gen_food_reviews_2_sentence_withdish_withsentiment.json'
fn1 = 'data/gen_food_reviews_1_sentence_withdish_withsentiment.json'

en_stopwords = list(stopwords.words('english'))
set_punc = set(['$', '.', ':', '--', ',', '(', ')', '"', '``', 'SYM'])
wordcloud_data = defaultdict(int)


def read_review_file(filename, rating):
    for line in open(filename).readlines():
        review_json = json.loads(line)
        dishes = review_json.get('dish')
        if TEST_WORD not in dishes:
            continue

        sentences = review_json.get('text', [])
        for s in sentences:
            if TEST_WORD not in s:
                continue
            read_sentence(s, rating)


def read_sentence(sentence, rating):
    tokens = TweetTokenizer().tokenize(sentence)
    for token in tokens:
        if token in TEST_WORD or token in set_punc or token in en_stopwords:
            continue
        wordcloud_data[token] += rating

if __name__ == '__main__':
    read_review_file(fn5, 5)
    read_review_file(fn4, 4)
    read_review_file(fn3, 3)
    read_review_file(fn2, 2)
    read_review_file(fn1, 1)
    wc = WordCloud()
    wc.generate_from_frequencies(wordcloud_data.items())
    wc.to_file('example.jpg')
