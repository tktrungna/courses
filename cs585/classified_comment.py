from __future__ import division

import math
import os
import re
import json
from nltk.corpus import stopwords

from collections import defaultdict

en_stopwords = set(stopwords.words('english'))

# Global class labels.
POS_LABEL = 'pos'
NEG_LABEL = 'neg'

# Path to dataset
PATH_TO_DATA = "."

option = ['bow', 'bow_sent', 'tf-idf']

file1 = 'data/gen_food_reviews_1_sentence_withdish_withsentiment.json'
file2 = 'data/gen_food_reviews_2_sentence_withdish_withsentiment.json'
file3 = 'data/gen_food_reviews_3_sentence_withdish_withsentiment.json'
file4 = 'data/gen_food_reviews_4_sentence_withdish_withsentiment.json'
file5 = 'data/gen_food_reviews_5_sentence_withdish_withsentiment.json'

def tokenize_doc(doc):
    bow = {}
    #for w in doc.split():#re.findall(r"[\w']+", doc):
    for w in re.findall(r"[\w']+", doc):
        w = w.lower()
        if w in en_stopwords:
            continue
        if not bow.get(w):
            bow[w] = 1
        else:
            bow[w] += 1
    return bow

# sentiment-to-score map - gives higher score to more positive word/sentence
sent_map = {'Very positive':5, 'Positive':4, 'Neutral':3, 'Negative':2, 'Very negative':1}
set_punc = set(['$', '.', ':', '--', ',', '(', ')', '"', '``', 'SYM'])

def tokenize_review(word, sent, option):
    bow = {}
    #for w in doc.split():#re.findall(r"[\w']+", doc):
    #print sent
    for i in range(len(word)):
        for j in range(len(word[i])):
            if len(word[i][j]) < 3:
                #print word[i][j]
                #print word
                continue
            w = word[i][j][0]
            if option == 'bow':
                s = 1
            elif option == 'bow_sent':
                s = sent_map[word[i][j][1]]
            #print w, s
            if word[i][j][0] in en_stopwords or word[i][j][2] in set_punc:
                continue
            if not bow.get(w):
                bow[w] = 1.0*s
            else:
                bow[w] += 1.0*s
    #print bow
    #abc
    return bow

class NaiveBayes:
    def __init__(self,option):
        self.vocab = set()
        self.class_total_doc_counts = { POS_LABEL: 0.0,
                                        NEG_LABEL: 0.0 }
        self.class_total_word_counts = { POS_LABEL: 0.0,
                                         NEG_LABEL: 0.0 }
        self.class_word_counts = { POS_LABEL: defaultdict(float),
                                   NEG_LABEL: defaultdict(float) }
        self.total_doc_counts = 0
        self.option = option

    # read POS-tagged review file and update NB model
    def read_review(self, file, label, start, end):
        for l in open(file).readlines()[start:end]:
            l = json.loads(l,'utf8')

            # list[list[list]] - list of all sentences, with tokens, POS tag of tokens
            # and sentimental analysis label
            word_sent = l['word_sent']
            # list of sentimental analysis results for each sentence in review
            sen_sent = l['sentiment']
            self.tokenize_and_update_model(word_sent, sen_sent, label)

    def train_model(self, num_docs=None):
        self.read_review(file5, POS_LABEL,0,6000)
        self.read_review(file4, POS_LABEL,0,6000)
        self.read_review(file3, NEG_LABEL,0,4000)
        self.read_review(file2, NEG_LABEL,0,4000)
        self.read_review(file1, NEG_LABEL,0,4000)
        self.report_statistics_after_training()

    def report_statistics_after_training(self):
        print "REPORTING CORPUS STATISTICS"
        print "NUMBER OF DOCUMENTS IN POSITIVE CLASS:", self.class_total_doc_counts[POS_LABEL]
        print "NUMBER OF DOCUMENTS IN NEGATIVE CLASS:", self.class_total_doc_counts[NEG_LABEL]
        print "NUMBER OF TOKENS IN POSITIVE CLASS:", self.class_total_word_counts[POS_LABEL]
        print "NUMBER OF TOKENS IN NEGATIVE CLASS:", self.class_total_word_counts[NEG_LABEL]
        print "VOCABULARY SIZE: NUMBER OF UNIQUE WORDTYPES IN TRAINING CORPUS:", len(self.vocab)
        print "FEATURE:", self.option

    def update_model(self, bow, label):
        for w in bow.keys():
            if not self.class_word_counts[label].get(w):
                self.class_word_counts[label][w] = bow[w]
            else:
                self.class_word_counts[label][w] += bow[w]
            self.class_total_word_counts[label] += bow[w]
            if w not in self.vocab:
                self.vocab.add(w)
        self.class_total_doc_counts[label] += 1
        self.total_doc_counts = (self.class_total_doc_counts[POS_LABEL] +
                                 self.class_total_doc_counts[NEG_LABEL])

    def tokenize_and_update_model(self, word_sent, sen_sent, label):
        #bow = tokenize_doc(doc)
        bow = tokenize_review(word_sent, sen_sent, self.option)
        self.update_model(bow, label)

    def top_n(self, label, n):
        sorted_words_count = sorted(self.class_word_counts[label].items(),
                                    key=lambda (w,c): -c)
        return sorted_words_count[:n]

    def p_word_given_label(self, word, label):
        return (self.class_word_counts[label].get(word,0)/
                self.class_total_word_counts[label])

    def p_word_given_label_and_psuedocount(self, word, label, alpha):
        return ((self.class_word_counts[label].get(word,0)+alpha)/
                (self.class_total_word_counts[label]+len(self.vocab)*alpha))

    def log_likelihood(self, bow, label, alpha):
        loglikelihood = 0
        for w in bow.keys():
            loglikelihood += math.log(self.p_word_given_label_and_psuedocount(w, label, alpha))
        return loglikelihood

    def log_prior(self, label):
        return math.log(self.class_total_doc_counts[label]/self.total_doc_counts)

    def unnormalized_log_posterior(self, bow, label, alpha):
        return self.log_prior(label)+self.log_likelihood(bow, label, alpha)

    def classify(self, bow, alpha):
        if (self.unnormalized_log_posterior(bow, POS_LABEL, alpha) >=
            self.unnormalized_log_posterior(bow, NEG_LABEL, alpha)):
            return POS_LABEL
        else:
            return NEG_LABEL

    def likelihood_ratio(self, word, alpha):
        return (self.p_word_given_label_and_psuedocount(word,POS_LABEL,alpha)/
                self.p_word_given_label_and_psuedocount(word,NEG_LABEL,alpha))

    def read_testing(self, file, label, alpha, start, end):
        corrected_doc = 0
        for l in open(file).readlines()[start:end]:
            l = json.loads(l,'utf8')
            word_sent = l['word_sent']
            sen_sent = l['sentiment']
            bow = tokenize_review(word_sent, sen_sent, self.option)
            pred_label = self.classify(bow, alpha)
            corrected_doc +=int(label == pred_label)
        return corrected_doc

    def evaluate_classifier_accuracy(self, alpha, num_docs=None):
        corrected_doc = 0
        total_doc = 6000
        corrected_doc += self.read_testing(file5, POS_LABEL, alpha, 6000, 7500)#1200:1500
        corrected_doc += self.read_testing(file4, POS_LABEL, alpha, 6000, 7500)
        corrected_doc += self.read_testing(file3, NEG_LABEL, alpha, 4000, 5000)#2666
        corrected_doc += self.read_testing(file2, NEG_LABEL, alpha, 4000, 5000)
        corrected_doc += self.read_testing(file1, NEG_LABEL, alpha, 4000, 5000)
        return corrected_doc/total_doc

def plot_psuedocount_vs_accuracy(psuedocounts, accuracies):
    import matplotlib.pyplot as plt

    plt.plot(psuedocounts, accuracies)
    plt.xlabel('Psuedocount Parameter')
    plt.ylabel('Accuracy (%)')
    plt.title('Psuedocount Parameter vs. Accuracy Experiment')
    plt.show()

if __name__ == '__main__':
    nb = NaiveBayes(option[1])
    nb.train_model(num_docs=None)
    alpha = 1
    accuracies = nb.evaluate_classifier_accuracy(alpha,num_docs=None)
    print "ACCURACY:", accuracies

psuedocounts = [2**i for i in range(-10,6)]
accuracies = list()
for alpha in psuedocounts:
    accuracies.append(nb.evaluate_classifier_accuracy(alpha,num_docs=None))
print psuedocounts
print accuracies
print max(accuracies)

plot_psuedocount_vs_accuracy(psuedocounts, accuracies)