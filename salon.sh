#! /bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"

: << 'COMMENT'
MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "Welcome to Our Salon, How may I help you?" 
  echo -e "\n1. Book an appointment\n2. Cancel an appointment\n3. Exit"
  read MAIN_MENU_SELECTION

  case $MAIN_MENU_SELECTION in
    1) PICK_SERVICE ;;
    2) CANCEL_SERVICE ;;
    3) EXIT ;;
    *) MAIN_MENU "Please enter a valid option." ;;
  esac
}
COMMENT
PICK_SERVICE () {
  # Print greetings and ask how we may help
  echo -e "\nWhat service would you like to schedule?\n"
  # Get service info and print as requested
  SERVICES=$($PSQL "SELECT service_id, name FROM services;")
  # Vars
  SERVICE_ID_MIN=999
  SERVICE_ID_MAX=0
  while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
    if [ $SERVICE_ID -lt $SERVICE_ID_MIN ]
    then
      SERVICE_ID_MIN=$SERVICE_ID
    elif [ $SERVICE_ID -gt $SERVICE_ID_MAX ]
    then
      SERVICE_ID_MAX=$SERVICE_ID
    fi
  done <<<$(echo "$SERVICES")
  #echo "$(($SERVICE_ID_MAX+1))) Exit"
  # Read service to offer for booking
  read SERVICE_ID_SELECTED
  # Check if number exists in the services
  if  [[ ! $SERVICE_ID_SELECTED =~ ^[$SERVICE_ID_MIN-$SERVICE_ID_MAX]+$ ]]
  then
    #send to pick service menu 
    #echo -e "\nPlease enter a valid number to pick a service."
    PICK_SERVICE 
  elif [[ $SERVICE_ID_SELECTED == $(($SERVICE_ID_MAX+1)) ]]
  then
    # Send to exit menu
    EXIT
  else 
    # Get Phone Number
    echo -e " \nPerfect, What's your phone number?"
    read CUSTOMER_PHONE
    #Check if customer exists with this number 
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';";)
    if [[ -z $CUSTOMER_NAME ]]
    then
      # Ask, read name and create customer
      echo -e "\nI don't have a record for that phone number, what's your name please?"
      read CUSTOMER_NAME
      INSERT_NEW_CUSTOMER=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
      # Get customer id 
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
    else
      # Get customer id 
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")
    fi
    # Get name of service
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

    # Ask when to book appointment
    echo -e "\nWhat time would you like your$SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME
    INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(service_id, customer_id, time) VALUES ($SERVICE_ID_SELECTED, $CUSTOMER_ID, '$SERVICE_TIME');")
    if [[ $INSERT_APPOINTMENT == 'INSERT 0 1' ]]
    then
      echo -e "\nI have put you down for a$SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

: << 'COMMENT'
CANCEL_SERVICE () {
  # Vars
  SERVICE_ID_MIN=999999
  SERVICE_ID_MAX=0
  #Get customer info 
  echo -e "\nWhat's your phone number?"
  read PHONE_NUMBER
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$PHONE_NUMBER';")
  # if not customer id found return to main menu
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nSorry, you haven't scheduled an oppointment with this phone number."
    MAIN_MENU 
  else
    CUSTOMER_AP=$($PSQL "SELECT * FROM services INNER JOIN appointments USING(service_id) INNER JOIN customers USING(customer_id) WHERE phone = '$PHONE_NUMBER' ORDER BY service_id;")
    # Show appointments scheduled
    echo -e "\nHere are your appointments:"
    # to fix the fucking loop that does not read/print well the second line tested to add another bar at the end does not work, in the second line prints "|) | for $NAME" if i remember well
    while read CUSTOMER_ID BAR SERVICE_ID BAR NAME BAR APPOINTMENT_ID BAR TIME BAR PHONE BAR NAME
    do
      echo "$APPOINTMENT_ID) Appointment on $TIME for $NAME"
      if [ $SERVICE_ID -lt $SERVICE_ID_MIN ]
      then
        SERVICE_ID_MIN=$SERVICE_ID
      elif [ $SERVICE_ID -gt $SERVICE_ID_MAX ]
      then
       SERVICE_ID_MAX=$SERVICE_ID
      fi
    done <<<$(echo "$CUSTOMER_AP")

    # ask for appointment to cancel
    echo -e "\nWhich one would you like to cancel?"
    read SERVICE_ID_TO_CANCEL

    # if not a number
    if [[ ! $SERVICE_ID_TO_CANCEL =~ ^[$SERVICE_ID_MIN-$SERVICE_ID_MAX]+$ ]]
    then
      # send to main menu
      MAIN_MENU "That is not a valid number."
    else
      # cancel appointment
      CANCEL=$($PSQL "UPDATE appointments SET time = 'Canceled' WHERE appointment_id = $SERVICE_ID_TO_CANCEL;")
      # send to main menu
      echo -e "\nAppointment canceled." 
      MAIN_MENU
    fi
  fi
}
COMMENT

EXIT() {
  echo -e "\nThank you for visiting us, we hope to see you soon again.\n"
}
PICK_SERVICE
#MAIN_MENU
