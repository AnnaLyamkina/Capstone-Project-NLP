library(dplyr)
library(tidyr)
library(tidytext)
library(readr)


server <- function(input, output, session) {
    
    # read in files with 4grams, 3grams and 2grams. They are sorted 
    #by frequency and separated into individual words
    
    if(!exists("bigrams80")) {
        bigrams80 <- read.csv("bigrams80_separated_freq.csv.gz")
    }
    if(!exists("trigrams80")) {
        trigrams80 <- read.csv("trigrams80_separated_freq.csv.gz")
    }
    if(!exists("fourgrams80")) {
        fourgrams80 <- read.csv("fourgrams80_separated_freq.csv.gz")
    }
    #backup - three most popular single words
    if(!exists("unigrams")) {
        unigrams <- data.frame(word = c("the", "to", "i"))
    }
    
    is_enough <- function(candidates){
        if (candidates %>% distinct(word, .keep_all = TRUE) %>% nrow >=3){
            return (TRUE)
        } else {
            return (FALSE)
        }
        
    }
    
    #read the input from the user. We read in the whole text, process it 
    #and save the last 3gram as last_words for the predictive model
    last_words <- reactive({
        inputtext <- as.character(input$inputtext)
        replace_reg <- "[^a-zA-Z]"
        text <- gsub(replace_reg, ' ', inputtext)
        text <- tibble(text = text)
        input_words <-  text %>% unnest_tokens(word, text, token = "ngrams", n = 1) %>% drop_na()
        last_words <- data.frame(t(tail(input_words$word, n = 3)))
        colnames(last_words) <- c("word1", "word2", "word3")
        last_words

    })
    # show last words in the corresponding output, diagnostics only
    output$last_words <- renderText({
        #last_words()
        paste(last_words()[1,], collapse = " ")
    })
    
    #main part: get the list of candidates list. We separate last words 
    #into individual words and apply a simple model:
    # 1. look for an exact match in fourgrams
    # 2. look for an exact match in trigrams
    # 3. look for a soft match (words 1 and 3 or 1 and 2) in fourgrams.
    # Get unique, sort by frequency.
    # 4. look for a match in bigrams
    # 
    # Before coming to the next step we check if the candidate list 
    # is already long enough
    candidates <- reactive({
        #separate input into words
        #input <- data.frame("text" = last_words())
        #input_words <- separate(input, col = "text", into = c("word1", "word2", "word3"), sep = " ")
        input_words <- last_words()
        #initialize candidates
        #candidates <- data.frame(word = character)
        #get candidates from a strict fourgram match
        from_fourgram_strict <- fourgrams80 %>% filter(word1 == input_words$word1 & 
            word2 == input_words$word2  & word3 == input_words$word3) %>% 
            arrange(desc(n)) %>% select(word4) %>% rename(word = word4)
        #get candidates from a trigram match
        from_trigram <- trigrams80 %>% filter(word1 == input_words$word2 & 
            word2 == input_words$word3) %>% select(word3) %>% rename(word = word3)
        #get candidates from a soft fourgram match
        from_fourgram_soft <- fourgrams80 %>% filter(word1 == input_words$word1 & 
            word2 == input_words$word2 | word1 == input_words$word1 & word3 == input_words$word3) %>% 
            arrange(desc(n)) %>% select(word4) %>% distinct(word4, .keep_all = TRUE)  %>% 
            rename(word = word4) 
        #get candidates from a bigram match
        from_bigram <- bigrams80 %>% filter(word1 == input_words$word3) %>% 
            select(word2) %>% rename(word = word2)
        
        candidates <- bind_rows(from_fourgram_strict, from_trigram, from_fourgram_soft, from_bigram, unigrams) %>% 
            distinct(word, .keep_all = TRUE) %>% head(n=5)
        #candidates
        
    })
    
    #output candidates
    
    output$candidates<-renderDT({
        DT::datatable(candidates(), options = list(lengthMenu = c(5,10),pageLength = 5))
        },server=FALSE, selection = list(mode='single',target="cell"))
    
    observeEvent(input$candidates_cell_clicked,{
        info=input$candidates_cell_clicked
        print(info$value)
        if (!(is.null(info$value)||info$col==0))
        {
            updateTextInput(session,'inputtext',value=paste0(input$inputtext, " ", info$value)) # assuming you want to concatenate the two
            # if you want to just update the cell do value=info$value
        }
        
    })
    
}