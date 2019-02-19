/* E2 Library - JS */

/*-----------------------------------------------------------*/
/* Starter code - DO NOT edit the code below. */
/*-----------------------------------------------------------*/

// global counts
let numberOfBooks = 0; // total number of books
let numberOfPatrons = 0; // total number of patrons

// global arrays
const libraryBooks = [] // Array of books owned by the library (whether they are loaned or not)
const patrons = [] // Array of library patrons.

// Book 'class'
class Book {
	constructor(title, author, genre) {
		this.title = title;
		this.author = author;
		this.genre = genre;
		this.patron = null; // will be the patron objet

		// set book ID
		this.bookId = numberOfBooks;
		numberOfBooks++;
	}

	setLoanTime() {
		// Create a setTimeout that waits 3 seconds before indicating a book is overdue

		const self = this; // keep book in scope of anon function (why? the call-site for 'this' in the anon function is the DOM window)
		setTimeout(function() {
			
			console.log('overdue book!', self.title)
			changeToOverdue(self);

		}, 3000)

	}
}

// Patron constructor
const Patron = function(name) {
	this.name = name;
	this.cardNumber = numberOfPatrons;

	numberOfPatrons++;
}


// Adding these books does not change the DOM - we are simply setting up the 
// book and patron arrays as they appear initially in the DOM.
libraryBooks.push(new Book('Harry Potter', 'J.K. Rowling', 'Fantasy'));
libraryBooks.push(new Book('1984', 'G. Orwell', 'Dystopian Fiction'));
libraryBooks.push(new Book('A Brief History of Time', 'S. Hawking', 'Cosmology'));

patrons.push(new Patron('Jim John'))
patrons.push(new Patron('Kelly Jones'))

// Patron 0 loans book 0
libraryBooks[0].patron = patrons[0]
// Set the overdue timeout
libraryBooks[0].setLoanTime()  // check console to see a log after 3 seconds


/* Select all DOM form elements you'll need. */ 
const bookAddForm = document.querySelector('#bookAddForm');
const bookInfoForm = document.querySelector('#bookInfoForm');
const bookLoanForm = document.querySelector('#bookLoanForm');
const patronAddForm = document.querySelector('#patronAddForm');

/* bookTable element */
const bookTable = document.querySelector('#bookTable')
/* bookInfo element */
const bookInfo = document.querySelector('#bookInfo')
/* Full patrons entries element */
const patronEntries = document.querySelector('#patrons')

/* Event listeners for button submit and button click */

bookAddForm.addEventListener('submit', addNewBookToBookList);
bookLoanForm.addEventListener('submit', loanBookToPatron);
patronAddForm.addEventListener('submit', addNewPatron)
bookInfoForm.addEventListener('submit', getBookInfo);

/* Listen for click patron entries - will have to check if it is a return button in returnBookToLibrary */
patronEntries.addEventListener('click', returnBookToLibrary)

/*-----------------------------------------------------------*/
/* End of starter code - do *not* edit the code above. */
/*-----------------------------------------------------------*/


/** ADD your code to the functions below. DO NOT change the function signatures. **/


/*** Functions that don't edit DOM themselves, but can call DOM functions 
     Use the book and patron arrays appropriately in these functions.
 ***/

// Adds a new book to the global book list and calls addBookToLibraryTable()
function addNewBookToBookList(e) {
	e.preventDefault();

	// Add book book to global array
	const bookName = document.querySelector("#newBookName").value;
	const bookAuthor = document.querySelector("#newBookAuthor").value;
	const bookGenre = document.querySelector("#newBookGenre").value;
	

	// enhancement
	if (bookName.length == 0 || bookAuthor == 0 || bookGenre == 0) {
		alert('Error message: please provide enough information if you want add book to the library');
		return

	}

	const newBook = new Book(bookName, bookAuthor, bookGenre)
	libraryBooks.push(newBook)

	// Call addBookToLibraryTable properly to add book to the DOM
	addBookToLibraryTable(newBook)
	
}

// Changes book patron information, and calls 
function loanBookToPatron(e) {
	e.preventDefault();

	// Get correct book and patron
	const bookIDString = document.querySelector("#loanBookId").value;
	const patronIDString = document.querySelector("#loanCardNum").value;

	const bookID = parseInt(bookIDString);
	const patronID = parseInt(patronIDString);


	if (bookID > numberOfBooks - 1 || numberOfBooks < 0) {
		alert('Error message: No found of book');

	}

	if (patronID > numberOfPatrons - 1 || numberOfPatrons < 0) {
		alert('Error message: No found of patron');

	}

	if (libraryBooks[bookID].patron != null) {
		alert('Error message: Book already in use!');
	}


	// Add patron to the book's patron property
	if (!isNaN(bookID) && !isNaN(patronID)) {
		if (bookID >= 0 && bookID <= numberOfBooks && patronID >= 0 && patronID <= numberOfPatrons) {
			for (let i = 0; i < libraryBooks.length; i++) {
				if (libraryBooks[i].bookId == bookID && libraryBooks[i].patron == null) {
					libraryBooks[i].patron = patrons[patronID];
					// Add book to the patron's book table in the DOM by calling addBookToPatronLoans()
					addBookToPatronLoans(libraryBooks[i])
					// Start the book loan timer.
					libraryBooks[i].setLoanTime();
				}
			}
		}
	}
}



// Changes book patron information and calls returnBookToLibraryTable()
function returnBookToLibrary(e){
	e.preventDefault();
	// check if return button was clicked, otherwise do nothing.
	if (!e.target.classList.contains("return")) {
		return 
	}

	// Call removeBookFromPatronTable()
	const bookID = parseInt(e.target.parentElement.parentElement.children[0].innerText);
	const targetBook = libraryBooks[bookID];
	removeBookFromPatronTable(targetBook);
	// Change the book object to have a patron of 'null'
	targetBook.patron = null;

}

// Creates and adds a new patron

function addNewPatron(e) {
	e.preventDefault();

	// Add a new patron to global array

	const patronName = document.querySelector("#newPatronName").value;
	
	if (patronName.length == 0) {
		alert('Error message: please provide valid name');
		return;
	} 
	const newPatron = new Patron(patronName)

	patrons.push(newPatron)

	// Call addNewPatronEntry() to add patron to the DOM
	addNewPatronEntry(newPatron)

}

// Gets book info and then displays
function getBookInfo(e) {
	e.preventDefault();

	// Get correct book
	const bookIDString = document.querySelector("#bookInfoId").value;
	
	if (bookIDString == 0) {
		alert('Error message: please provide enough infomation');
	}


	if (bookID > numberOfBooks - 1 || numberOfBooks < 0) {
		alert('Error message: No found of book');

	}


	if (!isNaN(bookID)) {
		for (let i = 0; i < libraryBooks.length; i++) {
			if (libraryBooks[i].bookId == bookID) {
				// Call displayBookInfo()
				displayBookInfo(libraryBooks[i])
			}
		}
	}

		

}


/*-----------------------------------------------------------*/
/*** DOM functions below - use these to create and edit DOM objects ***/

// Adds a book to the library table.
function addBookToLibraryTable(book) {
	// Add code here
	const table = document.querySelector("#bookTable");
	const bookIdCell = document.createElement("td")
	const bookTitleCell = document.createElement("td")
	const bookPatronNumberCell = document.createElement("td")
	const strongEle = document.createElement("strong")
	const row = document.createElement("tr")

	bookIdCell.innerText = book.bookId
	strongEle.innerText = book.title
	bookTitleCell.appendChild(strongEle)
	bookPatronNumberCell.innerText = book.patron
	row.appendChild(bookIdCell)
	row.appendChild(bookTitleCell)
	row.appendChild(bookPatronNumberCell)
	table.append(row);


}


// Displays deatiled info on the book in the Book Info Section
function displayBookInfo(book) {
	// Add code here
	const table = document.querySelector("#bookInfo")
	bookInfo.children[0].children[0].innerText = book.bookId;
	bookInfo.children[1].children[0].innerText = book.title;
	bookInfo.children[2].children[0].innerText = book.author;
	bookInfo.children[3].children[0].innerText = book.genre;

	if (book.patron) {
		bookInfo.children[4].children[0].innerText = book.patron.name;
	}
	else {
		bookInfo.children[4].children[0].innerText = "N/A";
	}





}

// Adds a book to a patron's book list with a status of 'Within due date'. 
// (don't forget to add a 'return' button).
function addBookToPatronLoans(book) {
	
	// update bookTable information
	// check if book exist
	const bookTable = document.querySelector("#bookTable");
	const number = book.patron.cardNumber;

	for (let i = 1; i < bookTable.rows.length; i++) {
		if (parseInt(bookTable.rows[i].children[0].innerText) == book.bookId) {
			bookTable.rows[i].children[2].innerText = book.patron.cardNumber;
		}
	}

	// create new element
	const bookIDCell = document.createElement("td");
	const titleCell = document.createElement("td");
	const statusCell = document.createElement("td");
	const returnCell = document.createElement("td");
	const row = document.createElement("tr");
	
	const strongEle = document.createElement("strong");
	const greenSpan = document.createElement("span");
	const returnButton = document.createElement("button");

	bookIDCell.innerText = book.bookId

	strongEle.innerText = book.title;
	titleCell.appendChild(strongEle);

	greenSpan.className = "green";
	greenSpan.innerText = "Within due date";
	statusCell.appendChild(greenSpan);

	returnButton.className = "return";
	returnButton.innerText = "return";
	returnCell.appendChild(returnButton);

	row.appendChild(bookIDCell);
	row.appendChild(titleCell);
	row.appendChild(statusCell);
	row.appendChild(returnCell);

	// update patron table
	const patronList = document.querySelectorAll(".patron");
	for (let j = 0; j < patronList.length; j++) {
		if (parseInt(patronList[j].children[1].children[0].innerText) == book.patron.cardNumber) {
			patronList[j].children[3].appendChild(row)
		}
	}

	// enhancement
	const totalRow = bookTable.children[0].rows.length;
	for (let k = 1; k < totalRow; k++) {
		if (parseInt(bookTable.children[0].rows[k].children[0].innerText) == book.bookId) {
			const current = parseInt(bookTable.children[0].rows[k].children[3].innerText);
			bookTable.children[0].rows[k].children[3].innerText = current + 1;
		}
	}
	
	
}

// Adds a new patron with no books in their table to the DOM, including name, card number,
// and blank book list (with only the <th> headers: BookID, Title, Status).
function addNewPatronEntry(patron) {
	// Add code here
	const patronCell = document.createElement("div") 
	patronCell.className = "patron";

	const nameCell = document.createElement("p");
	const cardNumberCell = document.createElement("p");
	const headerCell = document.createElement("h4");
	const tableInfo = document.createElement("table");

	nameCell.innerText = "Name: ";
	const spanForName = document.createElement("span");
	spanForName.className = "bold";
	spanForName.innerText = patron.name;
	nameCell.appendChild(spanForName);

	cardNumberCell.innerText = "Card Number: "
	const spanForCardNumber = document.createElement("span");
	spanForCardNumber.className = "bold"
	spanForCardNumber.innerText = patron.cardNumber;
	cardNumberCell.appendChild(spanForCardNumber);

	headerCell.innerText = "Books on loan:";

	tableInfo.className = "patronLoansTable";
	rowCell = document.createElement("tr");
	bookIDCell = document.createElement("th");
	bookTitleCell = document.createElement("th");
	bookStatusCell = document.createElement("th");
	bookReturnCell = document.createElement("th");
	bookIDCell.innerText = "BookID";
	bookTitleCell.innerText = "Title";
	bookStatusCell.innerText = "Status";
	bookReturnCell.innerText = "Return";
	rowCell.appendChild(bookIDCell);
	rowCell.appendChild(bookTitleCell);
	rowCell.appendChild(bookStatusCell);
	rowCell.appendChild(bookReturnCell);
	tableInfo.appendChild(rowCell);

	patronCell.appendChild(nameCell);
	patronCell.appendChild(cardNumberCell);
	patronCell.appendChild(headerCell);
	patronCell.appendChild(tableInfo);

	const main = document.querySelector("#patrons");
	main.appendChild(patronCell);



}


// Removes book from patron's book table and remove patron card number from library book table
function removeBookFromPatronTable(book) {
	// Add code here

	// remove patron card number from library book table
	const libraryBookTable = document.querySelector("#bookTable");
	const len = libraryBookTable.rows.length
	for (let i = 0; i < len; i++) {
		bookIDInTable = parseInt(libraryBookTable.rows[i].children[0].innerText);
		if (bookIDInTable == book.bookId) {
			libraryBookTable.rows[i].children[2].innerText = null;
		}
	}


	// Removes book from patron's book table
	const list_ = document.querySelectorAll(".patron");
	for (let i = 0; i < list_.length; i++) {
		const table_ = list_[i].children[3];
		for (let j = 0; j < table_.rows.length; j++) {
			if (parseInt(table_.rows[j].children[0].innerText) == book.bookId) {
				table_.rows[j].remove();
			}
		}
	}


}

// Set status to red 'Overdue' in the book's patron's book table.
function changeToOverdue(book) {
	const patronList = document.querySelectorAll(".patron");
	for (let i = 0; i < patronList.length; i++) {
		if (book.patron != null) {
			if (parseInt(patronList[i].children[1].children[0].innerText) == book.patron.cardNumber) {
				const table_ = patronList[i].children[3]
				for (let j = 0; j < table_.rows.length; j++) {
					if (parseInt(table_.rows[j].children[0].innerText) == book.bookId) {
						table_.rows[j].children[2].className = "red";
            			table_.rows[j].children[2].innerText = "Overdue";
					}
				}

			}

		}
	}

}
