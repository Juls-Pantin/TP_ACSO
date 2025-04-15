#define _GNU_SOURCE
#include "ej1.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#ifndef LOG_INFO
#define LOG_INFO(x)
#endif

#ifndef LOG_ERROR
#define LOG_ERROR(x)
#endif

string_proc_list* string_proc_list_create(void){ //crear una lista vacia
	string_proc_list* list = malloc(sizeof(string_proc_list));
	if(list == NULL) return NULL;
	list->first = NULL;
	list->last  = NULL;
	return list;
}

string_proc_node* string_proc_node_create(uint8_t type, char* hash){ //crear un nodo
	if(hash == NULL) return NULL;
	string_proc_node* node = malloc(sizeof(string_proc_node));
	if(node == NULL) return NULL;
	node-> type = type;
	node->hash = strdup(hash);
	node->next = NULL;
	node->previous = NULL;
	return node;
}

void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){// agregar un nodo a la lista
	if(list == NULL || hash == NULL) return;
	string_proc_node* new_node = string_proc_node_create(type, hash);
	if(new_node == NULL) return;
	if(list->first == NULL){ //si la lista esta vacia
		list->first = new_node;
		list->last  = new_node;
	}else{ //si la lista no esta vacia
		new_node -> previous = list -> last;
		list -> last -> next = new_node;
		list -> last = new_node;
	}
	//list -> last -> next = new_node;
	}

char* string_proc_list_concat(string_proc_list* list, uint8_t type , char* hash){ 
    LOG_INFO("Concatenating hashes from the string processing list");
    if(list == NULL || hash == NULL) {
        LOG_ERROR("List or hash is NULL");
        return NULL;
    }
    char* result = strdup(hash); 
    string_proc_node* current = list->first;
    while(current != NULL){
        if(current->type == type){
            char* temp = str_concat(result, current->hash);
            free(result);
            result = temp;
        }
        current = current->next;
    }
    LOG_INFO("Hashes concatenated successfully");
    return result;
}

/** AUX FUNCTIONS **/

void string_proc_list_destroy(string_proc_list* list){

	/* borro los nodos: */
	string_proc_node* current_node	= list->first;
	string_proc_node* next_node		= NULL;
	while(current_node != NULL){
		next_node = current_node->next;
		string_proc_node_destroy(current_node);
		current_node	= next_node;
	}
	/*borro la lista:*/
	list->first = NULL;
	list->last  = NULL;
	free(list);
}
void string_proc_node_destroy(string_proc_node* node){
	node->next      = NULL;
	node->previous	= NULL;
	node->hash		= NULL;
	node->type      = 0;			
	free(node);
}


char* str_concat(char* a, char* b) {
	int len1 = strlen(a);
    int len2 = strlen(b);
	int totalLength = len1 + len2;
    char *result = (char *)malloc(totalLength + 1); 
    strcpy(result, a);
    strcat(result, b);
    return result;  
}

void string_proc_list_print(string_proc_list* list, FILE* file){
        uint32_t length = 0;
        string_proc_node* current_node  = list->first;
        while(current_node != NULL){
                length++;
                current_node = current_node->next;
        }
        fprintf( file, "List length: %d\n", length );
		current_node    = list->first;
        while(current_node != NULL){
                fprintf(file, "\tnode hash: %s | type: %d\n", current_node->hash, current_node->type);
                current_node = current_node->next;
        }
}